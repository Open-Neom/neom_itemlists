import 'package:http/http.dart' as http;
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_itemlists/itemlists/utils/constants/app_spotify_constants.dart';
import 'package:spotify/spotify.dart' as spotify;
import 'package:spotify_sdk/spotify_sdk.dart';

class SpotifyApiCalls {

  static Future<String> getSpotifyToken() async {
    AppUtilities.logger.d("Getting access and Spotify Token");
    String spotifyToken = "";

    if(await SpotifySdk.connectToSpotifyRemote(
      clientId: AppFlavour.getSpotifyClientId(),
      redirectUrl: AppSpotifyConstants.redirectUrl,)
    ) {
      spotifyToken = await SpotifySdk.getAccessToken(
          clientId: AppFlavour.getSpotifyClientId(),
          redirectUrl: AppSpotifyConstants.redirectUrl,
          scope: AppSpotifyConstants.scope
      );
    }

    AppUtilities.logger.i("Spotify Token Retrieved $spotifyToken");
    return spotifyToken;
  }


  static Future<spotify.User> getUserProfile({required String spotifyToken,}) async {

    spotify.SpotifyApi spotifyApi = spotify.SpotifyApi.withAccessToken(spotifyToken);
    spotify.User spotifyUser = spotify.User();

    try {
      spotifyUser = await spotifyApi.me.get();
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    AppUtilities.logger.i("The spotify userName is ${spotifyUser.displayName}");
    return spotifyUser;
  }

  static Future<List<spotify.PlaylistSimple>> getUserPlaylistSimples({required String spotifyToken, required String userId}) async {

    spotify.SpotifyApi spotifyApi = spotify.SpotifyApi.withAccessToken(spotifyToken);
    Iterable<spotify.PlaylistSimple> spotifyPlaylists = [];

    try {
      spotifyPlaylists = await spotifyApi.playlists.getUsersPlaylists(userId, 100).all();
      AppUtilities.logger.i("${spotifyPlaylists.length} playlists where retrieved from Spotify");
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    AppUtilities.logger.i("${spotifyPlaylists.length} were retrieved for Spotify User Id $userId");
    return spotifyPlaylists.toList();
  }


  static Future<List<spotify.Playlist>> getUserPlaylists({required String spotifyToken, required String userId}) async {

    spotify.SpotifyApi spotifyApi = spotify.SpotifyApi.withAccessToken(spotifyToken);
    Iterable<spotify.PlaylistSimple> spotifyPlaylists;
    List<spotify.Playlist> playlists = [];

    try {
      spotifyPlaylists = await spotifyApi.playlists.getUsersPlaylists(userId, 100).all();
      AppUtilities.logger.i("${spotifyPlaylists.length} playlists where retrieved from Spotify");
      
      for (var spotifyPlaylist in spotifyPlaylists.toList()) {
        if(spotifyPlaylist.id?.isNotEmpty ?? false) {
          AppUtilities.logger.d("Getting full info for Playlist ${spotifyPlaylist.name} with id ${spotifyPlaylist.id}");
          playlists.add(await spotifyApi.playlists.get(spotifyPlaylist.id!));
        }
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    AppUtilities.logger.i("${playlists.length} were retrieved for Spotify User Id $userId");
    return playlists;
  }

  static Future<http.Response?> getUserTopItems({required String spotifyToken, String itemType = "tracks"}) async {

    http.Response? response;

    try {
      Uri uri = Uri.parse('https://api.spotify.com/v1/me/top/$itemType');
      response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $spotifyToken',
        },
      );
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }


    AppUtilities. logger.i(response?.body ?? "");
    return response;
  }

  static Future<spotify.Playlist> getPlaylist({required String spotifyToken, required String playlistId}) async {

    spotify.SpotifyApi spotifyApi = spotify.SpotifyApi.withAccessToken(spotifyToken);
    spotify.Playlist playlist = spotify.Playlist();

    try {
      playlist = await spotifyApi.playlists.get(playlistId);
      AppUtilities.logger.i("Playlist ${playlist.name} were retrieved from Spotify");

    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return playlist;
  }

}
