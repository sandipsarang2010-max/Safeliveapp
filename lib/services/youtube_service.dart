import 'package:flutter/foundation.dart';
import 'package:googleapis/youtube/v3.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth;

class YouTubeService {
  Future<void> fetchLiveChat(GoogleSignInAccount? user) async {
    if (user == null) return;

    // 1. Define the scopes you need
    const List<String> scopes = [YouTubeApi.youtubeReadonlyScope];

    // 2. Obtain the authorization client for the specific scopes
    final authorization = await user.authorizationClient.authorizationForScopes(scopes);
    
    if (authorization == null) {
      debugPrint("Authorization failed");
      return;
    }

    // 3. Create the authenticated client
    final auth.AuthClient client = authorization.authClient(scopes: scopes);

    try {
      // 4. Initialize API and fetch data
      final youtubeApi = YouTubeApi(client);
      final response = await youtubeApi.channels.list(['snippet'], mine: true);
      
      debugPrint("Connected to: ${response.items?.first.snippet?.title}");
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      // Always close the client when done to release resources
      client.close();
    }
  }
}
