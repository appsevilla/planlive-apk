import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/plan_model.dart';
import '../models/comentario_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _usersRef => _firestore.collection('users');
  CollectionReference get _plansRef => _firestore.collection('plans');

  // ──────────────────────── USUARIOS ────────────────────────

  Future<void> createUser(UserModel user) async {
    await _usersRef.doc(user.uid).set(user.toMap());
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Future<void> updateUser(UserModel user) async {
    await _usersRef.doc(user.uid).update(user.toMap());
  }

  // ──────────────────────── PLANES ────────────────────────

  Future<List<PlanModel>> getPlansByUser(String userId) async {
    final query = await _plansRef.where('creatorId', isEqualTo: userId).get();
    return query.docs.map((doc) => PlanModel.fromDocument(doc)).toList();
  }

  Future<void> addPlan(PlanModel plan) async {
    await _plansRef.add(plan.toMap());
  }

  Future<void> updatePlan(PlanModel plan) async {
    await _plansRef.doc(plan.id).update(plan.toMap());
  }

  Future<void> deletePlan(String planId) async {
    await _plansRef.doc(planId).delete();
  }

  Future<PlanModel?> getPlanById(String planId) async {
    final doc = await _plansRef.doc(planId).get();
    if (doc.exists && doc.data() != null) {
      return PlanModel.fromDocument(doc);
    }
    return null;
  }

  // ──────────────────────── COMENTARIOS ────────────────────────

  Future<void> addComentario(String planId, Comentario comentario) async {
    final comentariosRef = _plansRef.doc(planId).collection('comentarios');
    await comentariosRef.add(comentario.toJson());
  }

  Stream<List<Comentario>> getComentarios(String planId) {
    final comentariosRef = _plansRef
        .doc(planId)
        .collection('comentarios')
        .orderBy('fecha', descending: true);

    return comentariosRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Comentario.fromJson(doc.data(), doc.id);
      }).toList();
    });
  }

  // ──────────────────────── LIKES ────────────────────────

  Future<void> likePlan(String planId, String userId) async {
    final likeRef = _plansRef.doc(planId).collection('likes').doc(userId);
    await likeRef.set({
      'userId': userId,
      'fecha': DateTime.now().toIso8601String(),
    });
  }

  Future<void> unlikePlan(String planId, String userId) async {
    final likeRef = _plansRef.doc(planId).collection('likes').doc(userId);
    await likeRef.delete();
  }

  Stream<int> getLikeCount(String planId) {
    return _plansRef
        .doc(planId)
        .collection('likes')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<bool> hasUserLiked(String planId, String userId) async {
    final doc = await _plansRef
        .doc(planId)
        .collection('likes')
        .doc(userId)
        .get();
    return doc.exists;
  }

  // ──────────────────────── SEGUIDORES ────────────────────────

  Future<void> followUser(String targetUserId, String followerId) async {
    final seguidoresRef =
    _usersRef.doc(targetUserId).collection('seguidores').doc(followerId);
    await seguidoresRef.set({
      'userId': followerId,
      'fecha': DateTime.now().toIso8601String(),
    });
  }

  Future<void> unfollowUser(String targetUserId, String followerId) async {
    final seguidoresRef =
    _usersRef.doc(targetUserId).collection('seguidores').doc(followerId);
    await seguidoresRef.delete();
  }

  Stream<int> getFollowersCount(String userId) {
    return _usersRef
        .doc(userId)
        .collection('seguidores')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<bool> isFollowing(String targetUserId, String followerId) async {
    final doc = await _usersRef
        .doc(targetUserId)
        .collection('seguidores')
        .doc(followerId)
        .get();
    return doc.exists;
  }
}

