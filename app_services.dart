import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/room.dart';

final db=FirebaseFirestore.instance; final auth=FirebaseAuth.instance;

class AuthService {
  String? verificationId;
  Future<void> sendOtp(String phone, void Function(String) codeSent) async {
    await auth.verifyPhoneNumber(phoneNumber:phone, verificationCompleted:(c) async=>await auth.signInWithCredential(c),
      verificationFailed:(e)=>throw Exception(e.message??'Phone verification failed'), codeSent:(id,_) {verificationId=id; codeSent(id);}, codeAutoRetrievalTimeout:(id)=>verificationId=id);
  }
  Future<UserCredential> verifyOtp(String code) async { final id=verificationId; if(id==null) throw Exception('OTP expired. Request a new code.');
    final cred=PhoneAuthProvider.credential(verificationId:id, smsCode:code); final r=await auth.signInWithCredential(cred);
    await db.collection('users').doc(r.user!.uid).set({'phone':r.user!.phoneNumber,'updatedAt':FieldValue.serverTimestamp()}, SetOptions(merge:true)); return r; }
}

class RoomService {
  Stream<List<Room>> rooms({String? city,int? maxRent}) { Query<Map<String,dynamic>> q=db.collection('rooms').where('status',isEqualTo:'approved').where('available',isEqualTo:true).orderBy('featured',descending:true).orderBy('createdAt',descending:true);
    if(city!=null && city.isNotEmpty) q=q.where('city',isEqualTo:city); if(maxRent!=null) q=q.where('rent',isLessThanOrEqualTo:maxRent);
    return q.snapshots().map((s)=>s.docs.map(Room.fromDoc).toList()); }
  Stream<List<Room>> myListings(String uid)=>db.collection('rooms').where('ownerId',isEqualTo:uid).orderBy('createdAt',descending:true).snapshots().map((s)=>s.docs.map(Room.fromDoc).toList());
  Future<String> create({required Map<String,dynamic> data, required List<XFile> images}) async {
    final uid=auth.currentUser!.uid, id=db.collection('rooms').doc().id; final urls=<String>[];
    for(final x in images){final ref=FirebaseStorage.instance.ref('rooms/$uid/$id/${const Uuid().v4()}.jpg'); await ref.putFile(File(x.path),SettableMetadata(contentType:'image/jpeg')); urls.add(await ref.getDownloadURL());}
    await db.collection('rooms').doc(id).set({...data,'ownerId':uid,'photos':urls,'status':'pending','verified':false,'featured':false,'available':true,'createdAt':FieldValue.serverTimestamp(),'updatedAt':FieldValue.serverTimestamp()}); return id;
  }
  Future<void> setAvailability(String id,bool value)=>db.collection('rooms').doc(id).update({'available':value,'updatedAt':FieldValue.serverTimestamp()});
}

class FavoriteService {
  Stream<bool> isFavorite(String roomId){final u=auth.currentUser; if(u==null)return Stream.value(false); return db.collection('users').doc(u.uid).collection('favorites').doc(roomId).snapshots().map((d)=>d.exists);}
  Future<void> toggle(Room room) async {final u=auth.currentUser!; final r=db.collection('users').doc(u.uid).collection('favorites').doc(room.id); final d=await r.get(); if(d.exists) await r.delete(); else await r.set({'roomId':room.id,'createdAt':FieldValue.serverTimestamp()});}
  Stream<List<String>> ids(){final u=auth.currentUser; if(u==null)return Stream.value(const []); return db.collection('users').doc(u.uid).collection('favorites').snapshots().map((s)=>s.docs.map((d)=>d.id).toList());}
}

class ChatService {
  String cid(String a,String b,String roomId)=>'${[a,b]..sort().join('_')}_$roomId';
  Stream<QuerySnapshot<Map<String,dynamic>>> messages(String conversationId)=>db.collection('conversations').doc(conversationId).collection('messages').orderBy('createdAt',descending:true).limit(100).snapshots();
  Future<void> send({required String conversationId,required String receiverId,required String text,required String roomId}) async {final u=auth.currentUser!; final c=db.collection('conversations').doc(conversationId); await c.set({'participants':[u.uid,receiverId],'roomId':roomId,'lastMessage':text,'lastSenderId':u.uid,'updatedAt':FieldValue.serverTimestamp()},SetOptions(merge:true)); await c.collection('messages').add({'senderId':u.uid,'receiverId':receiverId,'text':text,'createdAt':FieldValue.serverTimestamp(),'read':false});}
}

class NotificationService { Future<void> init() async {final u=auth.currentUser; if(u==null)return; final p=await FirebaseMessaging.instance.requestPermission(alert:true,badge:true,sound:true); if(p.authorizationStatus==AuthorizationStatus.denied)return; final t=await FirebaseMessaging.instance.getToken(); if(t!=null)await db.collection('users').doc(u.uid).collection('fcmTokens').doc(t).set({'createdAt':FieldValue.serverTimestamp()}); FirebaseMessaging.instance.onTokenRefresh.listen((t)=>db.collection('users').doc(u.uid).collection('fcmTokens').doc(t).set({'createdAt':FieldValue.serverTimestamp()}));}}

Future<Position?> currentPosition() async {if(!await Geolocator.isLocationServiceEnabled())return null; var p=await Geolocator.checkPermission(); if(p==LocationPermission.denied)p=await Geolocator.requestPermission(); if(p==LocationPermission.deniedForever||p==LocationPermission.denied)return null; return Geolocator.getCurrentPosition();}
