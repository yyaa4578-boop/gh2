import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ParentWebRTCPage extends StatefulWidget {
  final String roomId;

  const ParentWebRTCPage({Key? key, required this.roomId}) : super(key: key);

  @override
  _ParentWebRTCPageState createState() => _ParentWebRTCPageState();
}

class _ParentWebRTCPageState extends State<ParentWebRTCPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  RTCPeerConnection? _peerConnection;
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  @override
  void initState() {
    super.initState();
    _initRenderer();
    _startListening();
  }

  @override
  void dispose() {
    _remoteRenderer.dispose();
    _peerConnection?.close();
    super.dispose();
  }

  Future<void> _initRenderer() async {
    await _remoteRenderer.initialize();
  }

  Future<void> _startListening() async {
    Map<String, dynamic> configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ]
    };

    _peerConnection = await createPeerConnection(configuration);

    _peerConnection?.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        setState(() {
          _remoteRenderer.srcObject = event.streams[0];
        });
      }
    };

    final roomRef = _firestore.collection('rooms').doc(widget.roomId);
    final roomSnapshot = await roomRef.get();

    if (!roomSnapshot.exists) {
      // غرفة غير موجودة، يمكن التعامل مع الخطأ هنا
      return;
    }

    // قراءة الـ Offer من الطفل
    final data = roomSnapshot.data()!;
    final offer = data['offer'];

    await _peerConnection!.setRemoteDescription(
      RTCSessionDescription(offer['sdp'], offer['type']),
    );

    // إنشاء Answer والرد على الطفل
    RTCSessionDescription answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    await roomRef.update({
      'answer': {
        'type': answer.type,
        'sdp': answer.sdp,
      }
    });

    // إرسال ICE candidates إلى Firestore (calleeCandidates)
    _peerConnection?.onIceCandidate = (RTCIceCandidate? candidate) {
      if (candidate != null) {
        roomRef.collection('calleeCandidates').add(candidate.toMap());
      }
    };

    // قراءة ICE candidates المرسلة من الطفل (callerCandidates)
    roomRef.collection('callerCandidates').snapshots().listen((snapshot) {
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
        title: const Text('بث الطفل - الأب'),
      ),
      body: Center(
        child: RTCVideoView(_remoteRenderer),
      ),
    );
  }
}
