import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_signin_button/flutter_signin_button.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Youtube APP',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Youtube APP'),
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
  GoogleSignIn _googleSignIn =
      GoogleSignIn(scopes: ['email', 'https://www.googleapis.com/auth/youtube'],
          clientId: "622626307311-2vujec8emo1vp7acu2hcltr3jrk7q36b.apps.googleusercontent.com");
  bool _isLoggedIn = false;
  late GoogleSignInAccount _user;
  List<dynamic> _playlists = [];
  List<dynamic> _videos = [];
  String _selectedPlaylistId = '';

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

  Widget _buildLoginButton() {
    return Center(
      child: SignInButton(
        Buttons.Google,
        onPressed: _login,
        text: 'Sign in with Google',
      ),
    );
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
      body: _isLoggedIn
          ? Row(
              children: <Widget>[
                Container(
                  width: 200,
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
                  child: ListView.builder(
                    itemCount: _videos.length,
                    itemBuilder: (context, index) {
                      final video = _videos[index];
                      final snippet = video['snippet'];
                      final title = snippet['title'];
                      final thumbnail =
                          snippet['thumbnails']['medium']['url'];
                      return ListTile(
                        leading: Image.network(thumbnail),
                        title: Text(title),
                      );
                    },
                  ),
                ),
              ],
            )
          : _buildLoginButton(),
      floatingActionButton: _isLoggedIn
          ? FloatingActionButton(
              onPressed: _logout,
              child: Icon(Icons.logout),
            )
          : null,
    );
  }
}
