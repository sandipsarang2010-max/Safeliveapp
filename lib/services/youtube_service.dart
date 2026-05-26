import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/youtube/v3.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

class YouTubeService {
  Future<void> fetchLiveChat(GoogleSignInAccount? user) async {
    if (user == null) {
      debugPrint("Error: No user signed in.");
      return;
    }

    // 1. Define the specific scopes required for the YouTube API
    const List<String> scopes = [YouTubeApi.youtubeReadonlyScope];

    try {
      // 2. Obtain the authorization client for the specific user and scopes
      // This is the modern, non-deprecated way to request auth
      final authClient = await user.authClient(scopes: scopes);
      
      if (authClient == null) {
        debugPrint("Error: Failed to obtain authenticated client.");
        return;
      }

      // 3. Initialize the YouTube API using the authenticated client
      final youtubeApi = YouTubeApi(authClient);
      
      // 4. Fetch the data
      final response = await youtubeApi.channels.list(
        ['snippet'], 
        mine: true
      );
      
      debugPrint("Connected to: ${response.items?.first.snippet?.title}");
    } catch (e) {
      debugPrint("YouTube API Error: $e");
    }
  }
}
