import 'package:flutter/material.dart';
import 'package:hocky_na_org/services/mongodb_service.dart';
import 'package:intl/intl.dart';

class AdminUpdates extends StatefulWidget {
  const AdminUpdates({super.key});

  @override
  State<AdminUpdates> createState() => _AdminUpdatesState();
}

class _AdminUpdatesState extends State<AdminUpdates> {
  // State variables
  bool _isLoading = true;
  List<Map<String, dynamic>> _newsPosts = [];
  
  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isHighlighted = false;
  
  @override
  void initState() {
    super.initState();
    _fetchNewsPosts();
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
  
  // Fetch news posts from database
  Future<void> _fetchNewsPosts() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final newsCollection = MongoDBService.getCollection('news');
      final newsData = await newsCollection.find().toList();
      
      setState(() {
        _newsPosts = List<Map<String, dynamic>>.from(newsData);
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching news posts: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Reset form fields
  void _resetForm() {
    _titleController.clear();
    _subtitleController.clear();
    _contentController.clear();
    _isHighlighted = false;
  }
  
  // Show dialog to add a new news post
  Future<void> _showAddNewsDialog() async {
    _resetForm();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Post'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'Enter title',
                  ),
                  validator: (value) => value!.isEmpty ? 'Title is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _subtitleController,
                  decoration: const InputDecoration(
                    labelText: 'Subtitle/Brief',
                    hintText: 'Enter short subtitle or brief (optional)',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    labelText: 'Content',
                    hintText: 'Enter the full news content',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 5,
                  validator: (value) => value!.isEmpty ? 'Content is required' : null,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Highlight this post'),
                  subtitle: const Text('Featured posts appear prominently'),
                  value: _isHighlighted,
                  onChanged: (value) {
                    setState(() {
                      _isHighlighted = value;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                Navigator.pop(context);
                _addNewsPost();
              }
            },
            child: const Text('POST'),
          ),
        ],
      ),
    );
  }
  
  // Add a new news post to database
  Future<void> _addNewsPost() async {
    try {
      final newsCollection = MongoDBService.getCollection('news');
      
      await newsCollection.insert({
        'title': _titleController.text.trim(),
        'subtitle': _subtitleController.text.trim(),
        'content': _contentController.text.trim(),
        'isHighlighted': _isHighlighted,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'author': 'Admin', // In a real app, get this from user session
        'isActive': true,
      });
      
      _fetchNewsPosts(); // Refresh the list
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('News post published successfully')),
        );
      }
    } catch (e) {
      print('Error adding news post: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error publishing news: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // Show dialog to edit an existing news post
  Future<void> _showEditNewsDialog(Map<String, dynamic> post) async {
    // Set the controllers with existing values
    _titleController.text = post['title'] ?? '';
    _subtitleController.text = post['subtitle'] ?? '';
    _contentController.text = post['content'] ?? '';
    _isHighlighted = post['isHighlighted'] ?? false;
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit News Post'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'Enter news title',
                  ),
                  validator: (value) => value!.isEmpty ? 'Title is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _subtitleController,
                  decoration: const InputDecoration(
                    labelText: 'Subtitle/Brief',
                    hintText: 'Enter short subtitle or brief (optional)',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    labelText: 'Content',
                    hintText: 'Enter the full news content',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 5,
                  validator: (value) => value!.isEmpty ? 'Content is required' : null,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Highlight this post'),
                  subtitle: const Text('Featured posts appear prominently'),
                  value: _isHighlighted,
                  onChanged: (value) {
                    setState(() {
                      _isHighlighted = value;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                Navigator.pop(context);
                _updateNewsPost(post);
              }
            },
            child: const Text('UPDATE'),
          ),
        ],
      ),
    );
  }
  
  // Update an existing news post
  Future<void> _updateNewsPost(Map<String, dynamic> post) async {
    try {
      final newsCollection = MongoDBService.getCollection('news');
      
      await newsCollection.update(
        {'_id': post['_id']},
        {
          '\$set': {
            'title': _titleController.text.trim(),
            'subtitle': _subtitleController.text.trim(),
            'content': _contentController.text.trim(),
            'isHighlighted': _isHighlighted,
            'updatedAt': DateTime.now().toIso8601String(),
          }
        },
      );
      
      _fetchNewsPosts(); // Refresh the list
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('News post updated successfully')),
        );
      }
    } catch (e) {
      print('Error updating news post: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating news: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // Delete a news post
  Future<void> _deleteNewsPost(Map<String, dynamic> post) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete News Post'),
        content: Text('Are you sure you want to delete "${post['title']}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    try {
      final newsCollection = MongoDBService.getCollection('news');
      await newsCollection.remove({'_id': post['_id']});
      
      _fetchNewsPosts(); // Refresh the list
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('News post deleted successfully')),
        );
      }
    } catch (e) {
      print('Error deleting news post: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting news: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // Toggle visibility of a news post
  Future<void> _toggleNewsVisibility(Map<String, dynamic> post) async {
    try {
      final newsCollection = MongoDBService.getCollection('news');
      final newIsActive = !(post['isActive'] ?? true);
      
      await newsCollection.update(
        {'_id': post['_id']},
        {'\$set': {'isActive': newIsActive}},
      );
      
      _fetchNewsPosts(); // Refresh the list
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('News post ${newIsActive ? 'activated' : 'deactivated'} successfully')),
        );
      }
    } catch (e) {
      print('Error toggling news visibility: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error changing news visibility: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('News Management')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _newsPosts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'No news posts yet',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _showAddNewsDialog,
                        child: const Text('Create First News Post'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchNewsPosts,
                  child: ListView.builder(
                    itemCount: _newsPosts.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final post = _newsPosts[index];
                      final createdAt = DateTime.parse(post['createdAt'] ?? DateTime.now().toIso8601String());
                      final formattedDate = DateFormat('MMM d, yyyy').format(createdAt);
                      final isActive = post['isActive'] ?? true;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        color: isActive ? null : Colors.grey.shade200,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            if (post['isHighlighted'] == true)
                                              Padding(
                                                padding: const EdgeInsets.only(right: 8),
                                                child: Icon(
                                                  Icons.star,
                                                  color: Colors.amber,
                                                  size: 20,
                                                ),
                                              ),
                                            Expanded(
                                              child: Text(
                                                post['title'] ?? 'Untitled',
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Posted on $formattedDate',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          isActive ? Icons.visibility : Icons.visibility_off,
                                          color: isActive ? Colors.green : Colors.grey,
                                        ),
                                        onPressed: () => _toggleNewsVisibility(post),
                                        tooltip: isActive ? 'Hide post' : 'Show post',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () => _showEditNewsDialog(post),
                                        tooltip: 'Edit post',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () => _deleteNewsPost(post),
                                        tooltip: 'Delete post',
                                        color: Colors.red,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (post['subtitle'] != null && post['subtitle'].toString().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  post['subtitle'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              const Divider(),
                              const SizedBox(height: 8),
                              Text(
                                post['content'] ?? '',
                                style: const TextStyle(fontSize: 14),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () {
                                  // Show full content dialog
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text(post['title'] ?? 'Untitled'),
                                      content: SingleChildScrollView(
                                        child: Text(post['content'] ?? ''),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('CLOSE'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: const Text('View Full Content'),
                              ),
                              if (!isActive)
                                Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade400,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Hidden',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddNewsDialog,
        tooltip: 'Add News',
        child: const Icon(Icons.add),
      ),
    );
  }
}
