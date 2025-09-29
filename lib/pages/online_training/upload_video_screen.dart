import 'dart:async';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:the_factory/services/video_api_service.dart';

class UploadVideoScreen extends StatefulWidget {
  const UploadVideoScreen({super.key});

  @override
  State<UploadVideoScreen> createState() => _UploadVideoScreenState();
}

class _UploadVideoScreenState extends State<UploadVideoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _tagController = TextEditingController();

  File? _videoFile;
  File? _thumbnailFile;
  String _selectedCategory = 'General Lacrosse';
  bool _isPremium = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _uploadStatus = '';
  List<String> _tags = [];

  final List<String> _categories = [
    'Hand Speed',
    'General Lacrosse',
    'Shooting',
    'Defense',
    'Goalie',
    'Conditioning',
  ];

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        final file = File(video.path);
        final fileSizeInBytes = await file.length();
        final fileSizeInMB = fileSizeInBytes / (1024 * 1024);

        // Check file size (500MB limit)
        if (fileSizeInMB > 500) {
          _showErrorSnackBar('Video file too large. Maximum size is 500MB');
          return;
        }

        setState(() {
          _videoFile = file;
        });

        _showSuccessSnackBar(
          'Video selected: ${(fileSizeInMB).toStringAsFixed(1)}MB',
        );
      }
    } catch (e) {
      _showErrorSnackBar('Error picking video: $e');
    }
  }

  Future<void> _pickThumbnail() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image != null) {
        final file = File(image.path);
        final fileSizeInBytes = await file.length();
        final fileSizeInMB = fileSizeInBytes / (1024 * 1024);

        // Check file size (5MB limit)
        if (fileSizeInMB > 5) {
          _showErrorSnackBar('Thumbnail too large. Maximum size is 5MB');
          return;
        }

        setState(() {
          _thumbnailFile = file;
        });

        _showSuccessSnackBar('Thumbnail selected');
      }
    } catch (e) {
      _showErrorSnackBar('Error picking thumbnail: $e');
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag) && _tags.length < 10) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    } else if (_tags.length >= 10) {
      _showErrorSnackBar('Maximum 10 tags allowed');
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.black),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: const Color(0xFFB8FF00),
        ),
      );
    }
  }

  void _updateUploadProgress(double progress, String status) {
    if (mounted) {
      setState(() {
        _uploadProgress = progress;
        _uploadStatus = status;
      });
    }
  }

  Future<void> _uploadVideo() async {
    if (!_formKey.currentState!.validate()) return;

    if (_videoFile == null) {
      _showErrorSnackBar('Please select a video file');
      return;
    }

    if (_thumbnailFile == null) {
      _showErrorSnackBar('Please select a thumbnail image');
      return;
    }

    // Show confirmation dialog
    final shouldUpload = await _showUploadConfirmation();
    if (!shouldUpload) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _uploadStatus = 'Preparing upload...';
    });

    try {
      _updateUploadProgress(0.1, 'Validating files...');

      // Validate files exist and are readable
      if (!await _videoFile!.exists()) {
        throw Exception('Video file not found');
      }
      if (!await _thumbnailFile!.exists()) {
        throw Exception('Thumbnail file not found');
      }

      _updateUploadProgress(0.2, 'Starting upload...');

      // Simulate progress during upload since real progress tracking is complex
      Timer.periodic(Duration(milliseconds: 500), (timer) {
        if (!_isUploading) {
          timer.cancel();
          return;
        }

        if (_uploadProgress < 0.9) {
          setState(() {
            _uploadProgress += 0.05;
            _uploadStatus = 'Uploading... ${(_uploadProgress * 100).toInt()}%';
          });
        }
      });

      final response = await VideoApiService.uploadVideo(
        videoFile: _videoFile!,
        thumbnailFile: _thumbnailFile!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        tags: _tags,
        isPremium: _isPremium,
        price:
            _isPremium && _priceController.text.isNotEmpty
                ? double.tryParse(_priceController.text)
                : null,
        onProgress: (progress) {
          // This will be called when upload completes
          _updateUploadProgress(1.0, 'Upload completed!');
        },
      );

      _updateUploadProgress(1.0, 'Upload completed successfully!');

      await Future.delayed(const Duration(seconds: 1));

      if (response['success'] == true) {
        _showSuccessSnackBar('Video uploaded successfully!');

        // Return success result
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        throw Exception(
          response['message'] ?? 'Upload failed - no success response',
        );
      }
    } catch (e) {
      print('Upload error details: $e');
      _showErrorSnackBar('Upload failed: ${e.toString()}');

      setState(() {
        _uploadProgress = 0.0;
        _uploadStatus = '';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<bool> _showUploadConfirmation() async {
    final videoSize =
        _videoFile != null ? (await _videoFile!.length()) / (1024 * 1024) : 0;

    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                backgroundColor: const Color(0xFF2A2A2A),
                title: const Text(
                  'Confirm Upload',
                  style: TextStyle(color: Colors.white),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upload Details:',
                      style: TextStyle(color: Colors.white.withOpacity(0.9)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Title: ${_titleController.text}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      '• Category: $_selectedCategory',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      '• Type: ${_isPremium ? "Premium (\$${_priceController.text})" : "Free"}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      '• Video Size: ${videoSize.toStringAsFixed(1)}MB',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      '• Tags: ${_tags.join(", ")}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'This may take several minutes depending on your connection.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB8FF00),
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Upload'),
                  ),
                ],
              ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isUploading) {
          final shouldExit = await showDialog<bool>(
            context: context,
            builder:
                (context) => AlertDialog(
                  backgroundColor: const Color(0xFF2A2A2A),
                  title: const Text(
                    'Upload in Progress',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: const Text(
                    'Upload is in progress. Are you sure you want to cancel?',
                    style: TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Continue Upload'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Cancel Upload'),
                    ),
                  ],
                ),
          );
          return shouldExit ?? false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _isUploading ? null : () => Navigator.pop(context),
          ),
          title: const Text(
            'Upload Video',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Video File Picker
                    _buildSectionTitle('Video File'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _isUploading ? null : _pickVideo,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color:
                              _isUploading
                                  ? const Color(0xFF1A1A1A)
                                  : const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                _videoFile != null
                                    ? const Color(0xFFB8FF00)
                                    : const Color(0xFF404040),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _videoFile != null
                                  ? Icons.video_file
                                  : Icons.video_call,
                              color:
                                  _videoFile != null
                                      ? const Color(0xFFB8FF00)
                                      : Colors.white54,
                              size: 48,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _videoFile != null
                                  ? 'Video Selected: ${_videoFile!.path.split('/').last}'
                                  : _isUploading
                                  ? 'Upload in progress...'
                                  : 'Tap to select video',
                              style: TextStyle(
                                color:
                                    _videoFile != null
                                        ? const Color(0xFFB8FF00)
                                        : Colors.white70,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Thumbnail File Picker
                    _buildSectionTitle('Thumbnail Image'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _isUploading ? null : _pickThumbnail,
                      child: Container(
                        width: double.infinity,
                        height: 120,
                        decoration: BoxDecoration(
                          color:
                              _isUploading
                                  ? const Color(0xFF1A1A1A)
                                  : const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                _thumbnailFile != null
                                    ? const Color(0xFFB8FF00)
                                    : const Color(0xFF404040),
                          ),
                        ),
                        child:
                            _thumbnailFile != null
                                ? ClipRRect(
                                  borderRadius: BorderRadius.circular(11),
                                  child: Image.file(
                                    _thumbnailFile!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                                : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.image,
                                      color: Colors.white54,
                                      size: 40,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _isUploading
                                          ? 'Upload in progress...'
                                          : 'Tap to select thumbnail',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Title
                    _buildSectionTitle('Title'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      enabled: !_isUploading,
                      style: TextStyle(
                        color: _isUploading ? Colors.white54 : Colors.white,
                      ),
                      decoration: _buildInputDecoration('Enter video title'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Title is required';
                        }
                        if (value.trim().length < 3) {
                          return 'Title must be at least 3 characters';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Description
                    _buildSectionTitle('Description'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      enabled: !_isUploading,
                      style: TextStyle(
                        color: _isUploading ? Colors.white54 : Colors.white,
                      ),
                      decoration: _buildInputDecoration(
                        'Enter video description',
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Description is required';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Category
                    _buildSectionTitle('Category'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color:
                            _isUploading
                                ? const Color(0xFF1A1A1A)
                                : const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF404040)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          isExpanded: true,
                          style: TextStyle(
                            color: _isUploading ? Colors.white54 : Colors.white,
                          ),
                          dropdownColor: const Color(0xFF2A2A2A),
                          items:
                              _categories.map((category) {
                                return DropdownMenuItem<String>(
                                  value: category,
                                  child: Text(category),
                                );
                              }).toList(),
                          onChanged:
                              _isUploading
                                  ? null
                                  : (value) {
                                    if (value != null) {
                                      setState(() {
                                        _selectedCategory = value;
                                      });
                                    }
                                  },
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Tags
                    _buildSectionTitle('Tags'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _tagController,
                            enabled: !_isUploading,
                            style: TextStyle(
                              color:
                                  _isUploading ? Colors.white54 : Colors.white,
                            ),
                            decoration: _buildInputDecoration('Enter tag'),
                            onFieldSubmitted:
                                _isUploading ? null : (_) => _addTag(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _isUploading ? null : _addTag,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _isUploading
                                    ? Colors.grey
                                    : const Color(0xFFB8FF00),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.all(16),
                          ),
                          child: const Icon(Icons.add),
                        ),
                      ],
                    ),

                    if (_tags.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            _tags.map((tag) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      _isUploading
                                          ? Colors.grey
                                          : const Color(0xFFB8FF00),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      tag,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap:
                                          _isUploading
                                              ? null
                                              : () => _removeTag(tag),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.black,
                                        size: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Premium Toggle
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            _isUploading
                                ? const Color(0xFF1A1A1A)
                                : const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF404040)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Premium Video',
                                  style: TextStyle(
                                    color:
                                        _isUploading
                                            ? Colors.white54
                                            : Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _isPremium
                                      ? 'Users need to pay to watch this video'
                                      : 'This video will be free for all users',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isPremium,
                            onChanged:
                                _isUploading
                                    ? null
                                    : (value) {
                                      setState(() {
                                        _isPremium = value;
                                      });
                                    },
                            activeColor: const Color(0xFFB8FF00),
                            inactiveTrackColor: const Color(0xFF404040),
                          ),
                        ],
                      ),
                    ),

                    // Price Field (show only if premium)
                    if (_isPremium) ...[
                      const SizedBox(height: 16),
                      _buildSectionTitle('Price (\$)'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _priceController,
                        enabled: !_isUploading,
                        style: TextStyle(
                          color: _isUploading ? Colors.white54 : Colors.white,
                        ),
                        decoration: _buildInputDecoration('Enter price'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (_isPremium) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Price is required for premium videos';
                            }
                            final price = double.tryParse(value);
                            if (price == null || price <= 0) {
                              return 'Enter a valid price greater than 0';
                            }
                          }
                          return null;
                        },
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Upload Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isUploading ? null : _uploadVideo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isUploading
                                  ? Colors.grey
                                  : const Color(0xFFB8FF00),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child:
                            _isUploading
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                                : const Text(
                                  'Upload Video',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Upload Progress Overlay
            if (_isUploading)
              Container(
                color: Colors.black.withOpacity(0.8),
                child: Center(
                  child: Card(
                    color: const Color(0xFF2A2A2A),
                    margin: const EdgeInsets.all(24),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.cloud_upload,
                            color: Color(0xFFB8FF00),
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Uploading Video',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _uploadStatus,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          LinearProgressIndicator(
                            value: _uploadProgress,
                            backgroundColor: const Color(0xFF404040),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFB8FF00),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${(_uploadProgress * 100).toInt()}%',
                            style: const TextStyle(
                              color: Color(0xFFB8FF00),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Please keep the app open while uploading',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: _isUploading ? Colors.white54 : Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor:
          _isUploading ? const Color(0xFF1A1A1A) : const Color(0xFF2A2A2A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF404040)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF404040)),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFB8FF00)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }
}
