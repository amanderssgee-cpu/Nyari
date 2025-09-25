import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class EditBusinessPage extends StatefulWidget {
  final QueryDocumentSnapshot business;

  const EditBusinessPage({super.key, required this.business});

  @override
  State<EditBusinessPage> createState() => _EditBusinessPageState();
}

class _EditBusinessPageState extends State<EditBusinessPage> {
  // Text controllers
  late TextEditingController nameController,
      descController,
      categoryController,
      phoneController,
      websiteController,
      addressController,
      hoursController;

  File? insidePhoto, outsidePhoto, menuPhoto;
  double _uploadProgress = 1.0;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    final data = widget.business.data() as Map<String, dynamic>;
    nameController = TextEditingController(text: data['name']);
    descController = TextEditingController(text: data['description'] ?? '');
    categoryController = TextEditingController(text: data['category'] ?? '');
    phoneController = TextEditingController(text: data['phone'] ?? '');
    websiteController = TextEditingController(text: data['website'] ?? '');
    addressController = TextEditingController(text: data['address'] ?? '');
    hoursController = TextEditingController(text: data['hours'] ?? '');
  }

  Future<void> pickPhoto(String type) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() {
      if (type == 'inside') {
        insidePhoto = File(picked.path);
      } else if (type == 'outside')
        outsidePhoto = File(picked.path);
      else if (type == 'menu')
        menuPhoto = File(picked.path);
    });
  }

  Future<void> saveChanges() async {
    setState(() {
      _uploading = true;
      _uploadProgress = 0.0;
    });

    final docRef = FirebaseFirestore.instance
        .collection('businesses')
        .doc(widget.business.id);
    Map<String, dynamic> updates = {
      'name': nameController.text,
      'description': descController.text,
      'category': categoryController.text,
      'phone': phoneController.text,
      'website': websiteController.text,
      'address': addressController.text,
      'hours': hoursController.text,
    };

    final storageRef = FirebaseStorage.instance.ref();

    Future<void> uploadIfNotNull(File? photo, String field) async {
      if (photo != null) {
        final ref = storageRef.child(
          'businesses/${widget.business.id}/$field.jpg',
        );
        final task = ref.putFile(photo);
        task.snapshotEvents.listen((s) {
          setState(() {
            _uploadProgress = s.bytesTransferred / s.totalBytes;
          });
        });
        final snap = await task;
        updates['${field}Url'] = await snap.ref.getDownloadURL();
      }
    }

    await uploadIfNotNull(insidePhoto, 'insidePhoto');
    await uploadIfNotNull(outsidePhoto, 'outsidePhoto');
    await uploadIfNotNull(menuPhoto, 'menuPhoto');

    await docRef.update(updates);

    setState(() {
      _uploading = false;
      _uploadProgress = 1.0;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Saved!')));
    Navigator.pop(context);
  }

  Future<void> deleteListing() async {
    await FirebaseFirestore.instance
        .collection('businesses')
        .doc(widget.business.id)
        .delete();
    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Deleted listing')));
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.business.data() as Map<String, dynamic>;
    final insideUrl = data['insidePhotoUrl'] as String?;
    final outsideUrl = data['outsidePhotoUrl'] as String?;
    final menuUrl = data['menuPhotoUrl'] as String?;

    return Scaffold(
      appBar: AppBar(title: Text('Edit Business')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_uploadProgress < 1.0)
              LinearProgressIndicator(value: _uploadProgress),
            SizedBox(height: 12),

            if (insideUrl != null)
              Image.network(insideUrl, height: 100, width: 100),
            if (outsideUrl != null)
              Image.network(outsideUrl, height: 100, width: 100),
            if (menuUrl != null)
              Image.network(menuUrl, height: 100, width: 100),
            SizedBox(height: 12),

            _buildTextField(controller: nameController, label: 'Name'),
            _buildTextField(controller: descController, label: 'Description'),
            _buildTextField(controller: categoryController, label: 'Category'),
            _buildTextField(controller: phoneController, label: 'Phone'),
            _buildTextField(controller: websiteController, label: 'Website'),
            _buildTextField(controller: addressController, label: 'Address'),
            _buildTextField(controller: hoursController, label: 'Hours'),
            SizedBox(height: 12),

            _buildPhotoPicker(
              'Inside Photo',
              insidePhoto,
              () => pickPhoto('inside'),
            ),
            _buildPhotoPicker(
              'Outside Photo',
              outsidePhoto,
              () => pickPhoto('outside'),
            ),
            _buildPhotoPicker('Menu Photo', menuPhoto, () => pickPhoto('menu')),
            SizedBox(height: 24),

            ElevatedButton(
              onPressed: _uploading ? null : saveChanges,
              child:
                  _uploading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Save Changes'),
            ),
            SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: _uploading ? null : deleteListing,
              child: Text('Delete Listing'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Widget _buildPhotoPicker(String label, File? photo, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child:
              photo != null
                  ? Image.file(
                    photo,
                    height: 100,
                    width: 100,
                    fit: BoxFit.cover,
                  )
                  : Container(
                    height: 100,
                    width: 100,
                    color: Colors.grey[200],
                    child: Icon(Icons.add_a_photo),
                  ),
        ),
        SizedBox(height: 12),
      ],
    );
  }
}
