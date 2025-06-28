const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// 🔔 Construcción del payload FCM
function buildNotificationPayload(token, title, body, data = {}) {
  return {
    token,
    notification: { title, body },
    data,
    android: {
      priority: 'high',
      notification: {
        channelId: 'default_channel',
        sound: 'default',
      },
    },
    apns: {
      payload: {
        aps: {
          sound: 'default',
          contentAvailable: true,
        },
      },
    },
  };
}

// 📲 Enviar notificación push a un dispositivo
async function sendNotificationToDevice(token, title, body, data = {}) {
  if (!token) {
    console.warn('⚠️ Token FCM vacío o indefinido. No se envía notificación.');
    return;
  }

  const payload = buildNotificationPayload(token, title, body, data);

  try {
    const response = await admin.messaging().send(payload);
    console.log('✅ Notificación enviada:', response);
  } catch (error) {
    console.error('❌ Error al enviar notificación:', error);
  }
}

// 🔍 Extraer información básica del plan
function extractPlanDetails(planData) {
  const creatorId = planData.ownerId || planData.uid;
  const planTitulo = planData.titulo || 'tu plan';
  return { creatorId, planTitulo };
}

// 1️⃣ Notificar al creador cuando alguien se inscribe
exports.sendPlanNotification = functions.firestore
  .document('planes/{planId}/inscritos/{userId}')
  .onCreate(async (snap, context) => {
    const { planId, userId } = context.params;
    const inscritoData = snap.data();

    try {
      const planSnap = await admin.firestore().collection('planes').doc(planId).get();
      if (!planSnap.exists) return;

      const planData = planSnap.data();
      const { creatorId, planTitulo } = extractPlanDetails(planData);
      if (!creatorId) return;

      const creatorSnap = await admin.firestore().collection('users').doc(creatorId).get();
      const fcmToken = creatorSnap.data()?.fcmToken;
      if (!fcmToken) return;

      await sendNotificationToDevice(
        fcmToken,
        '🟢 Nuevo inscrito',
        `${inscritoData.nombre || 'Un usuario'} se ha inscrito en "${planTitulo}"`,
        { planId, userId }
      );
    } catch (error) {
      console.error('❌ Error al procesar inscripción:', error);
    }
  });

// 2️⃣ Notificar al creador cuando alguien se desinscribe
exports.onPlanUnsubscribed = functions.firestore
  .document('planes/{planId}/inscritos/{userId}')
  .onDelete(async (snap, context) => {
    const { planId, userId } = context.params;
    const inscritoData = snap.data();

    try {
      const planSnap = await admin.firestore().collection('planes').doc(planId).get();
      if (!planSnap.exists) return;

      const planData = planSnap.data();
      const { creatorId, planTitulo } = extractPlanDetails(planData);
      if (!creatorId) return;

      const creatorSnap = await admin.firestore().collection('users').doc(creatorId).get();
      const fcmToken = creatorSnap.data()?.fcmToken;
      if (!fcmToken) return;

      await sendNotificationToDevice(
        fcmToken,
        '🔴 Usuario se dio de baja',
        `${inscritoData.nombre || 'Un usuario'} se desinscribió de "${planTitulo}"`,
        { planId, userId }
      );
    } catch (error) {
      console.error('❌ Error al procesar baja:', error);
    }
  });

// 3️⃣ Notificar a los inscritos cuando el plan es editado
exports.onPlanUpdated = functions.firestore
  .document('planes/{planId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const { planId } = context.params;

    const cambios = [];
    if (before.fechaHora !== after.fechaHora) cambios.push('fecha u hora');
    if (before.ubicacion !== after.ubicacion) cambios.push('ubicación');
    if (before.titulo !== after.titulo) cambios.push('título');

    if (cambios.length === 0) return;

    const { planTitulo } = extractPlanDetails(after);

    try {
      const inscritosSnap = await admin.firestore()
        .collection(`planes/${planId}/inscritos`)
        .get();

      const notificaciones = inscritosSnap.docs.map(async (doc) => {
        const userId = doc.id;
        const userSnap = await admin.firestore().collection('users').doc(userId).get();
        const fcmToken = userSnap.data()?.fcmToken;
        if (!fcmToken) return;

        await sendNotificationToDevice(
          fcmToken,
          '✏️ Plan actualizado',
          `El plan "${planTitulo}" fue modificado (${cambios.join(', ')})`,
          { planId }
        );
      });

      await Promise.all(notificaciones);
    } catch (error) {
      console.error('❌ Error en actualización del plan:', error);
    }
  });

// 4️⃣ Notificar a los inscritos cuando el plan es eliminado
exports.onPlanDeleted = functions.firestore
  .document('planes/{planId}')
  .onDelete(async (snap, context) => {
    const planData = snap.data();
    const { planId } = context.params;
    const { planTitulo } = extractPlanDetails(planData);

    try {
      const inscritosSnap = await admin.firestore()
        .collection(`planes/${planId}/inscritos`)
        .get();

      const notificaciones = inscritosSnap.docs.map(async (doc) => {
        const userId = doc.id;
        const userSnap = await admin.firestore().collection('users').doc(userId).get();
        const fcmToken = userSnap.data()?.fcmToken;
        if (!fcmToken) return;

        await sendNotificationToDevice(
          fcmToken,
          '🗑️ Plan eliminado',
          `El plan "${planTitulo}" ha sido eliminado.`,
          { planId }
        );
      });

      await Promise.all(notificaciones);
    } catch (error) {
      console.error('❌ Error al notificar eliminación:', error);
    }
  });

// 5️⃣ Notificar a los inscritos cuando hay un nuevo mensaje en el chat
exports.onNewChatMessage = functions.firestore
  .document('planes/{planId}/chats/{chatId}')
  .onCreate(async (snap, context) => {
    const chatData = snap.data();
    const { planId } = context.params;
    if (!chatData) return null;

    try {
      const inscritosSnap = await admin.firestore()
        .collection(`planes/${planId}/inscritos`)
        .get();

      if (inscritosSnap.empty) return null;

      const tokens = [];
      const senderId = chatData.senderId;

      for (const doc of inscritosSnap.docs) {
        const userId = doc.id;
        if (userId === senderId) continue;

        const userSnap = await admin.firestore().collection('users').doc(userId).get();
        const token = userSnap.data()?.fcmToken;
        if (token) tokens.push(token);
      }

      if (tokens.length === 0) return null;

      const payload = {
        notification: {
          title: `Nuevo mensaje en el plan`,
          body: `${chatData.senderName || 'Alguien'}: ${chatData.message || ''}`,
          sound: 'default',
        },
        data: {
          planId,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
          type: 'chat_message',
        },
        android: {
          priority: 'high',
          notification: {
            channelId: 'default_channel',
            sound: 'default',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              contentAvailable: true,
            },
          },
        },
      };

      return admin.messaging().sendToDevice(tokens, payload);
    } catch (error) {
      console.error('❌ Error enviando notificación de chat:', error);
      return null;
    }
  });

// 6️⃣ Eliminar automáticamente planes expirados
exports.cleanExpiredPlans = functions.pubsub
  .schedule('every 1 hours')
  .timeZone('Europe/Madrid')
  .onRun(async () => {
    console.log('🧹 Ejecutando limpieza de planes expirados');

    const now = admin.firestore.Timestamp.now();
    const expiredPlansSnap = await admin.firestore()
      .collection('planes')
      .where('fechaHora', '<=', now)
      .get();

    if (expiredPlansSnap.empty) {
      console.log('✅ No hay planes expirados para eliminar.');
      return null;
    }

    for (const doc of expiredPlansSnap.docs) {
      const planId = doc.id;
      const planData = doc.data();

      try {
        const inscritosSnap = await admin.firestore()
          .collection(`planes/${planId}/inscritos`)
          .get();

        const batch = admin.firestore().batch();

        for (const inscritoDoc of inscritosSnap.docs) {
          const userId = inscritoDoc.id;
          const userPlanRef = admin.firestore().collection('users').doc(userId).collection('planes').doc(planId);
          batch.delete(userPlanRef);
          batch.delete(inscritoDoc.ref);
        }

        batch.delete(doc.ref);

        await batch.commit();
        console.log(`🗑️ Plan "${planData.titulo || planId}" eliminado automáticamente.`);
      } catch (error) {
        console.error(`❌ Error al eliminar plan "${planId}":`, error);
      }
    }

    return null;
  });

