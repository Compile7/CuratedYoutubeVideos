import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'video_item.dart';
import 'playlist_item.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/youtube',
    ],
    clientId:
        "622626307311-2vujec8emo1vp7acu2hcltr3jrk7q36b.apps.googleusercontent.com",
  );

  GoogleSignInAccount? _currentUser;
  bool _isLoggedIn = false;
  List<Map<String, dynamic>> _youtubePlaylist = [];
  bool _isLoading = false;
  bool _showPlaylist = false;
  List<Map<String, dynamic>> _youtubeVideos = [];
  bool _isVideoPlaying = false;
  bool _isLargeScreen = false;

  @override
  void initState() {
    super.initState();
    _checkIfLoggedIn();
  }

  Future<void> _checkIfLoggedIn() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? email = prefs.getString('email');

    if (email != null) {
      setState(() {
        _isLoggedIn = true;
      });
      _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
        setState(() {
          _currentUser = account;
        });
      });
      await _googleSignIn.signInSilently();

      _fetchYouTubePlaylist(); // Fetch playlist if already logged in
    }
  }

  Future<void> _handleSignIn() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser != null) {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('email', googleUser.email);
        setState(() {
          _isLoggedIn = true;
          _currentUser = googleUser;
        });

        _fetchYouTubePlaylist(); // Fetch playlist after successful login
      }
    } catch (error) {
      print('Error signing in: $error');
    }
  }

  Future<void> _handleSignOut() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('email');

      await _googleSignIn.disconnect();
      await _googleSignIn.signOut();
      setState(() {
        _isLoggedIn = false;
        _currentUser = null;
        _youtubePlaylist = [];
        _youtubeVideos = [];
      });
    } catch (error) {
      print('Error signing out: $error');
    }
  }

  Future<void> _fetchYouTubePlaylist() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final headers = await _googleSignIn.currentUser?.authHeaders;
      if (headers == null) {
        throw Exception('User is not authenticated.');
      }
      final response = await http.get(
        Uri.parse(
            'https://www.googleapis.com/youtube/v3/playlists?part=snippet&mine=true'),
        headers: {
          'Authorization': '${headers["Authorization"]}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List<dynamic>;
        setState(() {
          _youtubePlaylist = items
              .map<Map<String, dynamic>>((item) => {
                    'title': item['snippet']['title'],
                    'id': item['id'],
                  })
              .toList();
          _isLoading = false;
        });
      } else {
        print(
            'Error fetching YouTube playlist. Status code: ${response.statusCode}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (error) {
      print('Error fetching YouTube playlist: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchRelatedVideos(String playlistId) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final headers = await _googleSignIn.currentUser?.authHeaders;
      if (headers == null) {
        throw Exception('User is not authenticated.');
      }
      final response = await http.get(
        Uri.parse(
            'https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&playlistId=$playlistId'),
        headers: {
          'Authorization': '${headers["Authorization"]}',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List<dynamic>;
        setState(() {
          _youtubeVideos = items.map<Map<String, dynamic>>((item) {
            final snippet = item['snippet'];
            return {
              'id': snippet['resourceId']['videoId'],
              'thumbnailUrl': snippet['thumbnails']['high']['url'],
              'title': snippet['title'],
              'author': snippet['channelTitle'],
              'channel': snippet['channelTitle'],
            };
          }).toList();
          _isLoading = false;
        });
      } else {
        print(
            'Error fetching related videos. Status code: ${response.statusCode}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (error) {
      print('Error fetching related videos: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Youtube Playlist App'),
      ),
      drawer: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          _isLargeScreen = constraints.maxWidth > 200;
          return Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                backgroundImage:
                                    NetworkImage(_currentUser?.photoUrl ?? ''),
                                radius: 30,
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                _currentUser?.displayName ?? '',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                _currentUser?.email ?? '',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.white),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.arrow_back),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                color: Colors.white,
                              ),
                            ],
                          )
                        ],
                      ),
                    ],
                  ),
                ),
                if (_showPlaylist || _isLargeScreen) ..._buildPlaylistItems(),
                ListTile(
                  title: Text('Sign Out'),
                  leading: Icon(Icons.logout),
                  onTap: () {
                    Navigator.pop(context);
                    _handleSignOut();
                  },
                ),
              ],
            ),
          );
        },
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (!_isLoggedIn)
              ElevatedButton(
                child: Text('Sign In with Google'),
                onPressed: _handleSignIn,
              ),
            if (_isLoading)
              CircularProgressIndicator()
            else if (_isLoggedIn && _youtubeVideos.isEmpty)
              Text(
                  'Please click on any playlist to show videos. or video not found')
            else if (_isLoggedIn)
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: (_isLargeScreen)
                        ? (MediaQuery.of(context).size.width ~/ 200) ~/ 2
                        : MediaQuery.of(context).size.width ~/ 200,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: _youtubeVideos.length,
                  itemBuilder: (BuildContext context, int index) {
                    final video = _youtubeVideos[index];
                    return GestureDetector(
                      child: VideoItem(
                        video: video,
                        onTap: () {
                          setState(() {
                            _isVideoPlaying = true;
                          });
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Scaffold(
                                appBar: AppBar(
                                  leading: IconButton(
                                    icon: Icon(Icons.arrow_back),
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                  ),
                                  title: Text(video['title']),
                                ),
                                body: YoutubePlayerIFrame(
                                  controller: YoutubePlayerController(
                                    initialVideoId: video['id'],
                                    params: YoutubePlayerParams(
                                      playlist:_youtubeVideos.map<String>((video) => video['id']).toList(),
                                      showControls: true,
                                      showFullscreenButton: true,
                                      autoPlay: true,
                                    ),
                                  ),
                                  aspectRatio: 16 / 9,
                                ),
                              ),
                            ),
                          ).then((value) {
                            setState(() {
                              _isVideoPlaying = false;
                            });
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPlaylistItems() {
    return _youtubePlaylist.map((playlist) {
      return PlaylistItem(
        playlist: playlist,
        onTap: () {
          _fetchRelatedVideos(playlist['id']);
          setState(() {
            _showPlaylist = false;
          });
        },
      );
    }).toList();
  }
}
