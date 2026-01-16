import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:universal_html/html.dart' as html;
import '../../../models/news.dart';
import '../../../services/news_service.dart';

class ManageNewsScreen extends StatefulWidget {
  const ManageNewsScreen({Key? key}) : super(key: key);

  @override
  State<ManageNewsScreen> createState() => _ManageNewsScreenState();
}

class _ManageNewsScreenState extends State<ManageNewsScreen> {
  final NewsService _newsService = NewsService();
  final String _imageBbApiKey = '4a859feec3e15adfebf576f9bf215b39';

  // ==================== IMGBB UPLOAD LOGIC START ====================

  Future<String?> _uploadImageToImageBB(File imageFile) async {
    try {
      final uri = Uri.parse('https://api.imgbb.com/1/upload');
      final request = http.MultipartRequest('POST', uri)
        ..fields['key'] = _imageBbApiKey
        ..files.add(
          await http.MultipartFile.fromPath(
            'image',
            imageFile.path,
          ),
        );

      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);
      final jsonResponse = jsonDecode(responseString);

      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        return jsonResponse['data']['url'];
      } else {
        throw Exception('Failed to upload image: ${jsonResponse['error']['message']}');
      }
    } catch (e) {
      throw Exception('Image upload error: $e');
    }
  }

  Future<void> _pickAndUploadImage(
    TextEditingController imageUrlController,
    Function setModalState,
    BuildContext context, // Added context to show SnackBars
  ) async {
    try {
      if (kIsWeb) {
        // Web implementation
        final html.FileUploadInputElement uploadInput = html.FileUploadInputElement()
          ..accept = '.jpg,.png'
          ..click();

        uploadInput.onChange.listen((e) async {
          final files = uploadInput.files;
          if (files == null || files.isEmpty) return;

          final file = files[0];
          final reader = html.FileReader();

          final fileName = file.name.toLowerCase();
          if (!fileName.endsWith('.jpg') && !fileName.endsWith('.png')) {
             ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Invalid format! Only .jpg and .png are accepted.'),
                  backgroundColor: Colors.orange,
                ),
              );
            return;
          }

          setModalState(() {}); // Trigger rebuild to show loading if needed (though local var usage is better)

          reader.onLoad.listen((e) async {
            final bytes = reader.result as List<int>;
            await _uploadImageToImageBBWeb(bytes, file.name, imageUrlController, setModalState, context);
          });

          reader.readAsArrayBuffer(file);
        });
      } else {
        // Mobile implementation
        final ImagePicker picker = ImagePicker();
        final XFile? pickedFile = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 90,
        );

        if (pickedFile != null) {
          final imageFile = File(pickedFile.path);
          
          final fileName = imageFile.path.toLowerCase();
          if (!fileName.endsWith('.jpg') && !fileName.endsWith('.png')) {
             ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Invalid format! Only .jpg and .png are accepted.'),
                  backgroundColor: Colors.orange,
                ),
              );
            return;
          }

          setModalState(() {}); 

          final uploadedUrl = await _uploadImageToImageBB(imageFile);
          
          if (uploadedUrl != null) {
            setModalState(() {
              imageUrlController.text = uploadedUrl;
            });
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _uploadImageToImageBBWeb(
    List<int> imageBytes,
    String fileName,
    TextEditingController imageUrlController,
    Function setModalState,
    BuildContext context,
  ) async {
    try {
      final uri = Uri.parse('https://api.imgbb.com/1/upload');
      final request = http.MultipartRequest('POST', uri)
        ..fields['key'] = _imageBbApiKey
        ..files.add(
          http.MultipartFile.fromBytes(
            'image',
            imageBytes,
            filename: fileName,
          ),
        );

      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);
      final jsonResponse = jsonDecode(responseString);

      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        final uploadedUrl = jsonResponse['data']['url'];
        setModalState(() {
          imageUrlController.text = uploadedUrl;
        });
      } else {
         if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Upload failed: ${jsonResponse['error']['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }
  // ==================== IMGBB UPLOAD LOGIC END ====================

  void _showAddNewsDialog() {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    final imageUrlController = TextEditingController(); // Will hold the IBB URL
    final facebookUrlController = TextEditingController();
    final dateController = TextEditingController();

    // Default Date
    dateController.text = DateFormat('dd MMM, yyyy').format(DateTime.now());

    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Add News'),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Body
                      TextField(
                        controller: bodyController,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Body',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Image Selection Section (Replaces manual URL input)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'News Image',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          
                          if (isLoading)
                            const Center(child: CircularProgressIndicator())
                          else if (imageUrlController.text.isNotEmpty)
                             Column(
                               children: [
                                 ClipRRect(
                                   borderRadius: BorderRadius.circular(8),
                                   child: Image.network(
                                     imageUrlController.text,
                                     height: 150,
                                     width: double.infinity,
                                     fit: BoxFit.cover,
                                     errorBuilder: (_,__,___) => const Text("Error loading image"),
                                   ),
                                 ),
                                 const SizedBox(height: 8),
                                 SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () {
                                        setModalState(() {
                                          imageUrlController.clear();
                                        });
                                      },
                                      icon: const Icon(Icons.delete),
                                      label: const Text('Remove Photo'),
                                    ),
                                  ),
                               ],
                             )
                          else
                             SizedBox(
                              width: double.infinity,
                               child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                onPressed: () async {
                                  setModalState(() => isLoading = true);
                                  await _pickAndUploadImage(imageUrlController, setModalState, context);
                                  setModalState(() => isLoading = false);
                                },
                                icon: const Icon(Icons.add_photo_alternate),
                                label: const Text('Pick & Upload Photo'),
                              ),
                             ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Facebook Link
                      TextField(
                        controller: facebookUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Facebook Link (Optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Date
                      TextField(
                        controller: dateController,
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          border: OutlineInputBorder(),
                          helperText: 'e.g. 12 May, 2024',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : () async {
                    if (titleController.text.isNotEmpty && bodyController.text.isNotEmpty) {
                       final news = News(
                        id: '',
                        title: titleController.text,
                        body: bodyController.text,
                        date: dateController.text,
                        imageUrl: imageUrlController.text,
                        facebookUrl: facebookUrlController.text,
                      );

                      await _newsService.addNews(news);
                      if (context.mounted) Navigator.pop(context);
                    } else {
                       ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Title and Body are required.')),
                      );
                    }
                  },
                  child: const Text('Publish'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage News'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddNewsDialog,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<List<News>>(
        stream: _newsService.streamAllNews(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final newsList = snapshot.data ?? [];
          if (newsList.isEmpty) {
            return const Center(child: Text('No news items found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: newsList.length,
            itemBuilder: (context, index) {
              final news = newsList[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (news.imageUrl.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                news.imageUrl,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                              ),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  news.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  news.date,
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  news.body,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.grey[800]),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete News'),
                                  content: const Text('Are you sure you want to delete this item?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        await _newsService.deleteNews(news.id);
                                        if (context.mounted) Navigator.pop(ctx);
                                      },
                                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
