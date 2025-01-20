// import 'package:flutter/material.dart';
// import 'package:media_kit/media_kit.dart';
// import 'package:media_kit_video/media_kit_video.dart';
//
// class VideoPlayerScreen extends StatefulWidget {
//   final String videoUrl;
//
//   const VideoPlayerScreen({Key? key, required this.videoUrl}) : super(key: key);
//
//   @override
//   _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
// }
//
// class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
//   late final Player _player;
//   late final VideoController _videoController;
//
//   @override
//   void initState() {
//     super.initState();
//     _player = Player();
//     _videoController = VideoController(_player);
//
//     // Chargez la vidéo
//     _player.open(Media(widget.videoUrl));
//   }
//
//   @override
//   void dispose() {
//     _player.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: Video(
//           controller: _videoController,
//         ),
//       ),
//     );
//   }
// }
//
// class VerticalVideoListScreen extends StatefulWidget {
//   @override
//   _VerticalVideoListScreenState createState() =>
//       _VerticalVideoListScreenState();
// }
//
// class _VerticalVideoListScreenState extends State<VerticalVideoListScreen> {
//   final List<Map<String, String>> videoUrls = [
//     {
//       'url':
//       'https://www.sample-videos.com/video123/mp4/720/big_buck_bunny_720p_10mb.mp4',
//       'source': 'generic'
//     },
//     {
//       'url': 'https://www.sample-videos.com/video123/mp4/720/sample_5mb.mp4',
//       'source': 'generic'
//     },
//   ];
//
//   PageController _pageController = PageController();
//   bool autoScroll = false;
//   int currentIndex = 0;
//
//   @override
//   void initState() {
//     super.initState();
//     if (autoScroll) {
//       WidgetsBinding.instance.addPostFrameCallback((_) => autoScrollVideos());
//     }
//   }
//
//   void autoScrollVideos() async {
//     while (autoScroll && currentIndex < videoUrls.length - 1) {
//       await Future.delayed(Duration(seconds: 10));
//       _pageController.nextPage(
//           duration: Duration(milliseconds: 500), curve: Curves.easeInOut);
//     }
//   }
//
//   Widget buildVideoPlayer(String url, String source) {
//     return VideoPlayerScreen(
//       videoUrl: url,
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Video Player with MediaKit'),
//         actions: [
//           Switch(
//             value: autoScroll,
//             onChanged: (value) {
//               setState(() {
//                 autoScroll = value;
//                 if (autoScroll) autoScrollVideos();
//               });
//             },
//           ),
//         ],
//       ),
//       body: PageView.builder(
//         controller: _pageController,
//         scrollDirection: Axis.vertical,
//         onPageChanged: (index) {
//           setState(() {
//             currentIndex = index;
//           });
//         },
//         itemCount: videoUrls.length,
//         itemBuilder: (context, index) {
//           final video = videoUrls[index];
//           return buildVideoPlayer(video['url']!, video['source']!);
//         },
//       ),
//     );
//   }
// }
