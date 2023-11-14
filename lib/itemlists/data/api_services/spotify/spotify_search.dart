import 'dart:async';

import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/domain/model/item_list.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:spotify/spotify.dart';

import '../../../utils/constants/app_spotify_constants.dart';

class SpotifySearch {
  
  static SpotifyApi spotify = SpotifyApi(AppSpotifyConstants.getSpotifyCredentials());
  static Map<String, AppMediaItem> songs = {};
  static Map<String, Itemlist> giglists = {};

  static Future<Map<String, AppMediaItem>> searchSongs(String searchParam) async {
    AppUtilities.logger.t("Searching for songs by param: $searchParam}");

    try {
      var searchData = await spotify.search
          .get(searchParam.toLowerCase(),
            types: [SearchType.track])
          .first(20)
          .catchError((err) {
            AppUtilities.logger.e(err.toString());
            return err;
          });

      await loadSongsFromSpotify(searchData);

    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return songs;
  }

  static Future<void> loadSongsFromSpotify(List<Page<dynamic>> searchData) async {
    AppUtilities.logger.t("Retrieving songs from Spotify");
    songs.clear();
    try {
      for (var page in searchData) {
        for (var item in page.items!) {
          if (item is Track) {
            AppMediaItem song = AppMediaItem.mapTrackToSong(item);
            if(song.url.isNotEmpty) {
              songs[song.id] = song;
            } else {
              AppUtilities.logger.t("Media ${song.name} was found with no url so it was no added to songs list");
            }

          }
        }
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

  }


  Future<Map<String, Itemlist>> searchPlaylists(String searchParam) async {
    AppUtilities.logger.d("Searching for playlists");

    try {
      var searchData = await spotify.search
          .get(searchParam.toLowerCase(),
            types: [SearchType.playlist])
          .first(50);

      AppUtilities.logger.i("Retrieving playlists from Spotify");
      loadPlaylistsFromSpotify(searchData);

    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return giglists;
  }

  void loadPlaylistsFromSpotify(List<Page<dynamic>> searchData) async {

    try {
      for (var page in searchData) {
        for (var item in page.items!) {
          if (item is Playlist) {
            Itemlist giglist = await Itemlist.mapPlaylistToItemlist(item);
            giglists[giglist.id] = giglist;
          } else if (item is PlaylistSimple) {
            Itemlist giglist = Itemlist.mapPlaylistSimpleToItemlist(item);
            giglists[giglist.id] = giglist;
          }
        }
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    AppUtilities.logger.d("${giglists.length} playlists retrieved");
  }

  Future<Artist> loadArtistDetails(String artistId) async {
    AppUtilities.logger.d("Retrieving Details for artistId $artistId");
    Artist artist = Artist();

    try {
      artist = await spotify.artists.get(artistId);
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return artist;
  }

  Future<List<AppMediaItem>> loadSongsFromPlaylist(String playlistId) async {
    AppUtilities.logger.d("Loading songs from playlist $playlistId");
    List<AppMediaItem> playlistSongs = [];
    Playlist playlist = Playlist();

    try {
      playlist = await spotify.playlists.get(playlistId);

      if(playlist.tracks != null) {
        playlistSongs = AppMediaItem.mapTracksToSongs(playlist.tracks!);
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return playlistSongs;
  }

}
