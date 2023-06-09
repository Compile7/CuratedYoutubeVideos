import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Google Sign-In & YouTube Playlist',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Google Sign-In & YouTube Playlist'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'https://www.googleapis.com/auth/youtube'],
    clientId:
        "622626307311-2vujec8emo1vp7acu2hcltr3jrk7q36b.apps.googleusercontent.com",
  );
  bool _isLoggedIn = false;
  late GoogleSignInAccount _user;
  List<dynamic> _playlists = [];
  List<dynamic> _videos = [];
  String _selectedPlaylistId = '';
  bool _isPlayerVisible = false;
  String _selectedVideoUrl = '';

  void _login() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser != null) {
        setState(() {
          _isLoggedIn = true;
          _user = googleUser;
        });
        _fetchPlaylists();
      }
    } catch (error) {
      print('Error logging in: $error');
    }
  }

  void _logout() async {
    try {
      await _googleSignIn.signOut();
      setState(() {
        _isLoggedIn = false;
        _playlists.clear();
        _videos.clear();
        _selectedPlaylistId = '';
        _isPlayerVisible = false;
        _selectedVideoUrl = '';
      });
    } catch (error) {
      print('Error logging out: $error');
    }
  }

  Future<void> _fetchPlaylists() async {
    try {
      final accessToken = await _googleSignIn.currentUser!.authHeaders;
      final response = await http.get(
        Uri.parse(
          'https://www.googleapis.com/youtube/v3/playlists?part=snippet&mine=true',
        ),
        headers: accessToken,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _playlists = data['items'];
        });
      } else {
        print('Failed to load playlists. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching playlists: $error');
    }
  }

  Future<void> _fetchVideos(String playlistId) async {
    try {
      final accessToken = await _googleSignIn.currentUser!.authHeaders;
      final response = await http.get(
        Uri.parse(
          'https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&maxResults=10&playlistId=$playlistId',
        ),
        headers: accessToken,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _videos = data['items'];
        });
      } else {
        print('Failed to load videos. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching videos: $error');
    }
  }

  void _playVideo(String videoUrl) {
    setState(() {
      _isPlayerVisible = true;
      _selectedVideoUrl = videoUrl;
    });
  }

  void _closePlayer() {
    setState(() {
      _isPlayerVisible = false;
      _selectedVideoUrl = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          if (_isLoggedIn)
            Row(
              children: <Widget>[
                Text(
                  _user.displayName ?? '',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.account_circle),
                  onPressed: () {
                    setState(() {
                      _isLoggedIn = !_isLoggedIn;
                      _playlists.clear();
                      _videos.clear();
                      _selectedPlaylistId = '';
                    });
                  },
                ),
              ],
            ),
        ],
      ),
      body: Row(
        children: <Widget>[
          AnimatedContainer(
            duration: Duration(milliseconds: 500),
            width: _isPlayerVisible ? 0 : 200,
            child: ListView.builder(
              itemCount: _playlists.length,
              itemBuilder: (context, index) {
                final playlist = _playlists[index];
                return ListTile(
                  title: Text(playlist['snippet']['title']),
                  onTap: () {
                    final playlistId = playlist['id'];
                    setState(() {
                      _selectedPlaylistId = playlistId;
                    });
                    _fetchVideos(playlistId);
                  },
                );
              },
            ),
          ),
          Expanded(
            child: _isPlayerVisible
                ? Column(
                    children: [
                      Container(
                        height: 300,
                        child: YoutubePlayer(
                          controller: YoutubePlayerController(
                            initialVideoId: YoutubePlayer.convertUrlToId(
                                    _selectedVideoUrl) ??
                                '',
                            flags: YoutubePlayerFlags(
                              autoPlay: true,
                            ),
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _closePlayer,
                        child: Text('Back'),
                      ),
                    ],
                  )
                : GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 1,
                      childAspectRatio: 16 / 9,
                    ),
                    itemCount: _videos.length,
                    itemBuilder: (context, index) {
                      final video = _videos[index];
                      final snippet = video['snippet'];
                      final title = snippet['title'];
                      final thumbnail = snippet['thumbnails']['medium']['url'];
                      final videoId = video['id'];
                      final videoUrl =
                          'https://www.youtube.com/watch?v=$videoId';

                      return GestureDetector(
                        onTap: () => _playVideo(videoUrl),
                        child: Card(
                          child: Column(
                            children: [
                              Expanded(
                                child: Image.network(
                                  thumbnail,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  title,
                                  style: TextStyle(fontSize: 16),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: _isLoggedIn
          ? FloatingActionButton(
              onPressed: _logout,
              child: Icon(Icons.logout),
            )
          : FloatingActionButton(
              onPressed: _login,
              child: Icon(Icons.login),
            ),
    );
  }
}
