import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:files/features/previews/presentation/preview_action_bar.dart';
import 'package:flutter/material.dart';

import 'package:files/core/constants/icons.dart';
import 'package:files/core/theme/app_theme.dart';
import 'package:files/features/files_explorer/presentation/file_explorer.dart';

class AudioPreview extends StatefulWidget {
  final String filePath;
  final FileExplorerPageState? state;

  const AudioPreview({super.key, required this.filePath, this.state});

  @override
  State<AudioPreview> createState() => _AudioPreviewState();
}

class _AudioPreviewState extends State<AudioPreview> {
  final AudioPlayer _player = AudioPlayer();

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  bool _isPlaying = false;
  bool _showControls = true;

  double _volume = 1.0;
  double _previousVolume = 1.0;
  bool _isMuted = false;

  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _stateSub;

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  Future<void> _initAudio() async {
    await _player.setSource(DeviceFileSource(widget.filePath));
    await _player.setVolume(_volume);

    _durSub = _player.onDurationChanged.listen((d) {
      if (!mounted) return;
      setState(() => _duration = d);
    });

    _posSub = _player.onPositionChanged.listen((p) {
      if (!mounted) return;
      setState(() => _position = p);
    });

    _stateSub = _player.onPlayerStateChanged.listen((s) {
      if (!mounted) return;
      setState(() => _isPlaying = s == PlayerState.playing);
    });
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _stateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  String _format(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final m = two(d.inMinutes.remainder(60));
    final s = two(d.inSeconds.remainder(60));
    return "$m:$s";
  }

  Widget _buildTimeBubble() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.backgroundVariant.withOpacity(0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        "${_format(_position)} / ${_format(_duration)}",
        style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Text(widget.filePath.split('/').last),
      ),

      body: GestureDetector(
        onTap: () {
          setState(() => _showControls = !_showControls);
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: Image.asset(
                FileIcons.musicNote,
                color: AppColors.onSurfaceVariantDark,
              ),
            ),

            AnimatedOpacity(
              opacity: _showControls ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Container(color: Colors.black38),
            ),

            AnimatedOpacity(
              opacity: _showControls ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: GestureDetector(
                onTap: () async {
                  setState(() {
                    _isPlaying
                        ? _player.pause()
                        : _player.play(DeviceFileSource(widget.filePath));
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      /// BOTTOM BAR
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.backgroundVariant,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// SEEK + CONTROLS
            Stack(
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _isPlaying
                                ? _player.pause()
                                : _player.play(
                                  DeviceFileSource(widget.filePath),
                                );
                          });
                        },
                        icon: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: Builder(
                          builder: (context) {
                            final durationMs =
                                _duration.inMilliseconds.toDouble();
                            final positionMs =
                                _position.inMilliseconds.toDouble();

                            final sliderMax =
                                durationMs <= 0 ? 1.0 : durationMs;

                            final sliderValue = positionMs.clamp(
                              0.0,
                              sliderMax,
                            );

                            return Slider(
                              min: 0.0,
                              max: sliderMax,
                              value: sliderValue,
                              activeColor: AppColors.onBackground,
                              inactiveColor: AppColors.onSurfaceVariantDark,
                              onChanged: (v) {
                                _player.seek(Duration(milliseconds: v.toInt()));
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 14),

                      IconButton(
                        icon: Icon(
                          _isMuted ? Icons.volume_off : Icons.volume_up,
                          color: AppColors.onBackground,
                        ),
                        onPressed: () async {
                          setState(() {
                            _isMuted = !_isMuted;
                          });

                          if (_isMuted) {
                            // store current volume before muting
                            _previousVolume = _volume;
                            _volume = 0.0;
                          } else {
                            // restore previous volume
                            _volume = _previousVolume;
                          }

                          await _player.setVolume(_volume);
                        },
                      ),
                    ],
                  ),
                ),

                /// TIME BUBBLE
                Positioned(
                  top: -36,
                  left: 0,
                  right: 0,
                  child: Center(child: _buildTimeBubble()),
                ),
              ],
            ),

            /// ACTION BAR
            PreviewActionBar(
              path: widget.filePath,
              state: widget.state,
              rootContext: context,
            ),
          ],
        ),
      ),
    );
  }
}
