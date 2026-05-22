import 'package:flutter/material.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/widgets/images/artwork_color_aware_image.dart';

/// Playlist/itemlist header with artwork image and dynamic gradient
/// background tinted by the dominant color of the cover art.
///
/// Provides a Spotify-style visual header that adapts its gradient
/// to match the playlist artwork. Falls back to the app's default
/// accent color when no image is available or extraction fails.
class ItemlistColorHeader extends StatefulWidget {

  final String title;
  final String subtitle;
  final String imageUrl;
  final int itemCount;
  final VoidCallback? onPlayAll;
  final VoidCallback? onShuffle;

  const ItemlistColorHeader({
    super.key,
    required this.title,
    this.subtitle = '',
    this.imageUrl = '',
    this.itemCount = 0,
    this.onPlayAll,
    this.onShuffle,
  });

  @override
  State<ItemlistColorHeader> createState() => _ItemlistColorHeaderState();

}

class _ItemlistColorHeaderState extends State<ItemlistColorHeader> {

  Color _dominantColor = AppColor.getMain();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _dominantColor.withValues(alpha: 0.6),
            _dominantColor.withValues(alpha: 0.15),
            Colors.transparent,
          ],
          stops: const [0.0, 0.7, 1.0],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        children: [
          // Artwork
          if (widget.imageUrl.isNotEmpty)
            Center(
              child: SizedBox(
                width: 180,
                height: 180,
                child: ArtworkColorAwareImage(
                  imageUrl: widget.imageUrl,
                  width: 180,
                  height: 180,
                  borderRadius: BorderRadius.circular(8),
                  onColorExtracted: (color) {
                    if (mounted) setState(() => _dominantColor = color);
                  },
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Title
          Text(
            widget.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),

          // Subtitle + count
          if (widget.subtitle.isNotEmpty || widget.itemCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                widget.subtitle.isNotEmpty
                    ? '${widget.subtitle} · ${widget.itemCount} items'
                    : '${widget.itemCount} items',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              ),
            ),

          // Action buttons
          if (widget.onPlayAll != null || widget.onShuffle != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.onPlayAll != null)
                    _ActionButton(
                      icon: Icons.play_arrow_rounded,
                      label: 'Play',
                      color: _dominantColor,
                      onTap: widget.onPlayAll!,
                    ),
                  if (widget.onPlayAll != null && widget.onShuffle != null)
                    const SizedBox(width: 12),
                  if (widget.onShuffle != null)
                    _ActionButton(
                      icon: Icons.shuffle_rounded,
                      label: 'Shuffle',
                      color: Colors.white24,
                      onTap: widget.onShuffle!,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

}

class _ActionButton extends StatelessWidget {

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
