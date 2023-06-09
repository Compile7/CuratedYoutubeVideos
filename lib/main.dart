import 'package:first_project/style_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'videos_data.dart';
import 'video.dart';
import 'style_widgets.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void fetchPlaylists(String accessToken) async {
  final playlistsUrl = Uri.https(
    'www.googleapis.com',
    '/youtube/v3/playlists',
    {
      'part': 'snippet',
      'mine': 'true',
      // 'key': apiKey,
      'maxResults': '10', // Number of playlists to retrieve
    },
  );

  final response = await http.get(playlistsUrl, headers: {
    'Accept': 'application/json',
    'Authorization': 'Bearer ' + accessToken,
  });

  if (response.statusCode == 200) {
    final decodedResponse = json.decode(response.body);
    final playlists = decodedResponse['items'];

    for (var playlist in playlists) {
      final playlistId = playlist['id'];
      final playlistTitle = playlist['snippet']['title'];
      final playlistDescription = playlist['snippet']['description'];

      print('Playlist Title: $playlistTitle');
      print('Playlist Description: $playlistDescription');
      print('---');

      await fetchPlaylistItems(playlistId, accessToken);
    }
  } else {
    print('Error: ${response.statusCode}');
  }
}

void fetchPlaylistItems(String playlistId, String accessToken) async {
  final playlistItemsUrl = 'https://www.googleapis.com/youtube/v3/playlistItems/?part=id&part=snippet&part=contentDetails&part=status&maxResults=10&playlistId='+ playlistId;
  final uri = Uri.parse(playlistItemsUrl);
  final response = await http.get(uri, headers: {
    'Accept': 'application/json',
    'Authorization': 'Bearer ' + accessToken,
  });

  if (response.statusCode == 200) {
    final decodedResponse = json.decode(response.body);
    final videos = decodedResponse['items'];

    for (var video in videos) {
      final videoId = video['contentDetails']['videoId'];
      final videoTitle = video['snippet']['title'];
      final authorAvatar = video['snippet']['thumbnails']['default']['url'];
      final authorName = video['snippet']['channelTitle'];
      final subscribersCount = await fetchSubscriberCount(authorName, accessToken);
      final descriptionShort = video['snippet']['description'];
      final descriptionFull = await fetchVideoDescription(videoId, accessToken);
      // final likes = video['statistics']['likeCount'];
      // final dislikes = video['statistics']['dislikeCount'];
      // final comments = video['statistics']['commentCount'];
      // final views = video['statistics']['viewCount'];

      print('Video ID: $videoId');
      print('Video Title: $videoTitle');
      print('Author Avatar: $authorAvatar');
      print('Author Name: $authorName');
      print('Subscribers Count: $subscribersCount');
      print('Description (Short): $descriptionShort');
      print('Description (Full): $descriptionFull');
      // print('Likes: $likes');
      // print('Dislikes: $dislikes');
      // print('Comments: $comments');
      // print('Views: $views');
      print('---');
    }
  } else {
    print('Error: ${response.statusCode}');
  }
}

Future<int> fetchSubscriberCount(String channelName, String accessToken) async {
  final channelUrl = Uri.https(
    'www.googleapis.com',
    '/youtube/v3/channels',
    {
      'part': 'statistics',
      'forUsername': channelName,
      // 'key': apiKey,
    },
  );

  final response = await http.get(channelUrl, headers: {
    'Accept': 'application/json',
    'Authorization': 'Bearer ' + accessToken,
  });

  if (response.statusCode == 200) {
    final decodedResponse = json.decode(response.body);
    final subscriberCount = int.parse(decodedResponse['items'][0]['statistics']['subscriberCount']);

    return subscriberCount;
  } else {
    print('Error: ${response.statusCode}');
    return 0;
  }
}

Future<String> fetchVideoDescription(String videoId, String accessToken) async {
  final videoUrl = Uri.https(
    'www.googleapis.com',
    '/youtube/v3/videos',
    {
      'part': 'snippet',
      'id': videoId,
      // 'key': apiKey,
    },
  );

  final response = await http.get(videoUrl, headers: {
    'Accept': 'application/json',
    'Authorization': 'Bearer ' + accessToken,
  });

  if (response.statusCode == 200) {
    final decodedResponse = json.decode(response.body);
    final description = decodedResponse['items'][0]['snippet']['description'];

    return description;
  } else {
    print('Error: ${response.statusCode}');
    return '';
  }
}

String videoPreview;
String videoPreviewAuthor;
String videoPreviewTitle;
String videoPreviewDescriptionShort;

int clickedVideo;

double screenWidth;
double screenHeight;

class Card extends StatelessWidget {
  final Video video;
  Card(this.video);

  @override
  Widget build(BuildContext context) {
    // Disable screen rotation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    videoPreview = video.videoPreview;
    videoPreviewAuthor = video.authorAvatar;
    videoPreviewTitle = video.title;
    videoPreviewDescriptionShort = video.descriptionShort;

    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.width;

   

    // Video preview image
    return new Column(
      children: [
        GestureDetector(
            onTap: () {
              clickedVideo = int.parse(video.id);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SecondScreen()),
              );
            },
            child: Container(
              width: screenWidth,
              height: 225.0,
              margin: const EdgeInsets.only(bottom: 10.0),
              decoration: new BoxDecoration(
                image: DecorationImage(
                  image: new AssetImage(videoPreview),
                  fit: BoxFit.fill,
                ),
              ),
            )),

        // Row with authors avatar, video title, video description and icon
        Row(
          children: <Widget>[
            Container(
              child: new Avatar(), // Avatar
              width: 65.0,
            ),
            Column(children: <Widget>[
              Container(
                child: new Title(), // Title
                width: screenWidth - 140,
                margin: EdgeInsets.only(bottom: 10.0),
              ),
              Container(
                child: new Description(), // Description
                width: screenWidth - 140,
              ),
            ]),
            Container(
              child: new IconButton(
                icon: new Icon(
                  Icons.more_vert, // Icon
                  color: Colors.grey[700],
                ),
                onPressed: () {},
              ),
              width: screenWidth - 340,
              alignment: Alignment.bottomRight,
            ),
          ],
        ),

        // Separator (line)
        new MainSeparator(),
      ],
    );
  }
}

// Class for video authors avatar
class Avatar extends StatelessWidget {
  const Avatar({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new Container(
      alignment: Alignment.bottomLeft,
      child: Container(
        margin: const EdgeInsets.only(left: 15.0),
        width: 35.0,
        height: 35.0,
        decoration: new BoxDecoration(
          image: DecorationImage(
            image: new AssetImage(videoPreviewAuthor),
            fit: BoxFit.fill,
          ),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// Class for video title
class Title extends StatelessWidget {
  const Title({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new Text(
      videoPreviewTitle,
      style: TextStyle(
          color: Colors.grey[700], fontSize: 15.0, fontWeight: FontWeight.bold),
    );
  }
}

// Class for video description
class Description extends StatelessWidget {
  const Description({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new Text(
      videoPreviewDescriptionShort,
      style: TextStyle(color: Colors.grey[600], fontSize: 12.0),
    );
  }
}

void main() {
  var user;
  GoogleSignIn _googleSignIn = GoogleSignIn(
    // Pass scopes here
    scopes: [
      'email',
      'https://www.googleapis.com/auth/youtube'
    ],
    clientId: '622626307311-2vujec8emo1vp7acu2hcltr3jrk7q36b.apps.googleusercontent.com',
  );
  Future<void> _handleSignIn() async {
    try {
    user = await _googleSignIn.signIn();
    final auth = await user.authentication;
    final accessToken = auth.accessToken;
    print(user);
    print(auth);
    print(accessToken);
    fetchPlaylists(accessToken);
          } catch (error) {
      print(error);
    }
  }
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: new Image.asset('lib/images/logo.png', height: 20.0),
          backgroundColor: Colors.grey[50],
          elevation: 10.0,
          //title:Text(user==null?'':user.displayName),
          // Add new icon
          actions: [
            // new IconButton(
            //   icon: new Icon(Icons.camera_alt),
            //   onPressed: () {},
            // ),
            // new IconButton(
            //   icon: new Icon(Icons.search),
            //   onPressed: () {},
            // ),
            new Row(children: [
               new IconButton(
              icon: new Icon(Icons.face),
              onPressed: () {
                _handleSignIn();
              },
            ),
              // new Container(
              //   child: new Image.asset('lib/images/man.png',
              //       height: 25.0, width: 25.0),
              //   margin: EdgeInsets.only(left: 15.0, right: 15.0),
              // ),
            ]), // User avatar
          ],

          // Change style of icon
          iconTheme: IconThemeData(
            color: Colors.grey,
          ),

          textTheme: TextTheme(
            subtitle1: TextStyle(color: Colors.black, fontSize: 20.0),
          ),
        ),
        body: new ListView(
          children: new List.generate(4, (index) => new Card(videos[index])),
        ),
      ),
    ),
  );
}
