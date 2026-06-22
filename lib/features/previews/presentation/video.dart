import 'dart:io';

import 'package:mechanix_files/core/theme/app_theme.dart';
import 'package:mechanix_files/core/widgets/custom_icon_button.dart';
import 'package:mechanix_files/features/files_explorer/presentation/file_explorer.dart';
import 'package:mechanix_files/features/previews/presentation/preview_action_bar.dart';
import 'package:mechanix_files/features/previews/presentation/time_bubble.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPreview extends StatefulWidget {
  final BuildContext rootContext;
  final String filePath;
  final FileExplorerPageState? state;

  const VideoPreview({
    super.key,
    required this.filePath,
    required this.rootContext,
    this.state,
  });

  @override
  State<VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<VideoPreview> {
  late VideoPlayerController controller;

  bool _showControls = true;

  /// Prevents calling player methods after widget disposal.
  bool _isDisposed = false;

  /// Used while dragging slider.
  /// Without this, slider jumps back because player position
  /// continuously updates during drag.
  bool _isDragging = false;
  double _dragValue = 0.0;

  late VoidCallback _videoListener;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();

    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      controller = VideoPlayerController.file(File(widget.filePath))
        ..setLooping(false);

      await controller.initialize();

      if (!mounted) return;

      setState(() {});

      _videoListener = _onVideoUpdate;
      controller.addListener(_videoListener);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
      });
    }
  }

  void _onVideoUpdate() {
    if (!mounted || _isDisposed) return;
    if (_hasError || !controller.value.isInitialized) return;

    setState(() {});
  }

  @override
  void dispose() {
    _isDisposed = true;

    if (!_hasError) {
      /// Remove listener before disposing controller
      controller.removeListener(_videoListener);
      controller.pause();
      controller.dispose();
    }

    super.dispose();
  }

  /// Format duration into HH:MM:SS or MM:SS
  String _format(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');

    return h > 0 ? "$h:$m:$s" : "$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.black,
          elevation: 0,
          title: Text(widget.filePath.split('/').last),
        ),
        body: Center(
          child: Text(
            'Error loading video preview',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
        bottomNavigationBar: PreviewActionBar(
          path: widget.filePath,
          state: widget.state,
          rootContext: widget.rootContext,
        ),
      );
    }

    /// Show loader until video initializes
    if (!controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final position = controller.value.position;
    final duration = controller.value.duration;

    final durationMs = duration.inMilliseconds.toDouble();
    final positionMs = position.inMilliseconds.toDouble();
    final sliderMax = durationMs <= 0 ? 1.0 : durationMs;

    /// Prevent slider value from exceeding max
    final sliderValue = positionMs.clamp(0.0, sliderMax);

    /// While dragging, use drag value instead of player position
    final currentSliderValue = _isDragging ? _dragValue : sliderValue;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Text(widget.filePath.split('/').last),
      ),

      body: GestureDetector(
        onTap: () {
          setState(() {
            _showControls = !_showControls;
          });
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
            ),

            AnimatedOpacity(
              opacity: _showControls ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Container(color: Colors.black38),
            ),

            /// Center Play/Pause Button
            AnimatedOpacity(
              opacity: _showControls ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: GestureDetector(
                onTap: () async {
                  if (_isDisposed || !controller.value.isInitialized) {
                    return;
                  }

                  try {
                    if (controller.value.isPlaying) {
                      await controller.pause();
                    } else {
                      await controller.play();
                    }

                    if (mounted) {
                      setState(() {});
                    }
                  } catch (_) {}
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

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
            /// Player Controls
            Stack(
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      CustomIconButton.icon(
                        iconData:
                            controller.value.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                        iconSize: 28,
                        onPressed: () async {
                          if (_isDisposed || !controller.value.isInitialized) {
                            return;
                          }

                          try {
                            if (controller.value.isPlaying) {
                              await controller.pause();
                            } else {
                              await controller.play();
                            }

                            if (mounted) {
                              setState(() {});
                            }
                          } catch (_) {}
                        },
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 6,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 8,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 0,
                            ),
                          ),
                          child: Slider(
                            min: 0.0,
                            max: sliderMax,

                            /// Use drag value while dragging
                            value: currentSliderValue.clamp(0.0, sliderMax),

                            activeColor: Colors.white,
                            inactiveColor: Colors.white24,
                            thumbColor: Colors.white,

                            /// Start dragging
                            onChangeStart: (value) {
                              _isDragging = true;
                              _dragValue = value;
                            },

                            /// Update temporary drag position
                            onChanged: (value) {
                              setState(() {
                                _dragValue = value;
                              });
                            },

                            /// Seek only when user releases slider
                            /// This prevents continuous seek calls
                            onChangeEnd: (value) async {
                              if (_isDisposed ||
                                  !controller.value.isInitialized) {
                                return;
                              }

                              try {
                                await controller.seekTo(
                                  Duration(milliseconds: value.toInt()),
                                );
                              } catch (_) {}

                              if (mounted) {
                                setState(() {
                                  _isDragging = false;
                                });
                              }
                            },
                          ),
                        ),
                      ),

                      const SizedBox(width: 14),

                      CustomIconButton.icon(
                        iconData:
                            controller.value.volume > 0
                                ? Icons.volume_up
                                : Icons.volume_off,
                        iconSize: 28,
                        onPressed: () async {
                          try {
                            if (controller.value.volume > 0) {
                              await controller.setVolume(0);
                            } else {
                              await controller.setVolume(1);
                            }

                            if (mounted) {
                              setState(() {});
                            }
                          } catch (_) {}
                        },
                      ),
                    ],
                  ),
                ),

                Positioned(
                  top: -36,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: TimeBubble(
                      text: "${_format(position)} / ${_format(duration)}",
                    ),
                  ),
                ),
              ],
            ),

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
