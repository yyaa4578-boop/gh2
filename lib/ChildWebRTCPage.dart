import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChildWebRTCPage extends StatefulWidget {
  final String roomId; // معرف الغرفة المشتركة مع الأب

  const ChildWebRTCPage({Key? key, required this.roomId}) : super(key: key);

  @override
  _ChildWebRTCPageState createState() => _ChildWebRTCPageState();
}

class _ChildWebRTCPageState extends State<ChildWebRTCPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();

  @override
  void initState() {
    super.initState();
    _initRenderer();
    _startWebRTC();
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _localStream?.dispose();
    _peerConnection?.close();
    super.dispose();
  }

  Future<void> _initRenderer() async {
    await _localRenderer.initialize();
  }

  Future<void> _startWebRTC() async {
    // 1. الحصول على تدفق الوسائط (الكاميرا والمايكروفون)
    final mediaConstraints = {
      'audio': true,
      'video': {'facingMode': 'user'}
    };

    _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    _localRenderer.srcObject = _localStream;

    // 2. إنشاء PeerConnection مع سيرفر STUN
    Map<String, dynamic> configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ]
    };

    _peerConnection = await createPeerConnection(configuration);

    // 3. إضافة مسارات تدفق الوسائط إلى PeerConnection
    _localStream?.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, _localStream!);
    });

    // 4. التعامل مع ICE Candidates
    _peerConnection?.onIceCandidate = (RTCIceCandidate? candidate) {
      if (candidate != null) {
        _firestore
            .collection('rooms')
            .doc(widget.roomId)
            .collection('callerCandidates')
            .add(candidate.toMap());
      }
    };

    final roomRef = _firestore.collection('rooms').doc(widget.roomId);

    // 5. إنشاء Offer وإرساله إلى Firestore
    RTCSessionDescription offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    await roomRef.set({
      'offer': {
        'type': offer.type,
        'sdp': offer.sdp,
      }
    });

    // 6. الاستماع لرد Answer من الأب
    roomRef.snapshots().listen((snapshot) async {
      final data = snapshot.data();
      if (data != null && data.containsKey('answer')) {
        var answer = data['answer'];
        RTCSessionDescription remoteDesc =
            RTCSessionDescription(answer['sdp'], answer['type']);
        await _peerConnection!.setRemoteDescription(remoteDesc);
      }
    });

    // 7. الاستماع لICE candidates من الأب
    roomRef.collection('calleeCandidates').snapshots().listen((snapshot) {
      snapshot.docChanges.forEach((change) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data != null) {
            RTCIceCandidate candidate = RTCIceCandidate(
                data['candidate'], data['sdpMid'], data['sdpMLineIndex']);
            _peerConnection?.addCandidate(candidate);
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('بث الطفل - WebRTC'),
      ),
      body: Center(
        child: 
         RTCVideoView(_localRenderer),
      ),
    );
  }
}
