import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/listing.dart';
import '../providers/listing_provider.dart';
import '../services/firebase_service.dart';

class ListingForm extends ConsumerStatefulWidget {
  final Listing? listing;
  const ListingForm({super.key, this.listing});

  @override
  ConsumerState<ListingForm> createState() => _ListingFormState();
}

class _ListingFormState extends ConsumerState<ListingForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameC;
  late final TextEditingController _addressC;
  late final TextEditingController _phoneC;
  late final TextEditingController _descC;
  late final TextEditingController _latC;
  late final TextEditingController _lngC;
  String category = 'Restaurant';

  @override
  void initState() {
    super.initState();
    _nameC = TextEditingController(text: widget.listing?.name ?? '');
    _addressC = TextEditingController(text: widget.listing?.address ?? '');
    _phoneC = TextEditingController(text: widget.listing?.contactNumber ?? '');
    _descC = TextEditingController(text: widget.listing?.description ?? '');
    _latC = TextEditingController(
      text: widget.listing?.latitude.toString() ?? '-1.9536',
    );
    _lngC = TextEditingController(
      text: widget.listing?.longitude.toString() ?? '30.0606',
    );
    category = widget.listing?.category ?? 'Restaurant';
  }

  @override
  void dispose() {
    _nameC.dispose();
    _addressC.dispose();
    _phoneC.dispose();
    _descC.dispose();
    _latC.dispose();
    _lngC.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseService.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sign in required')));
      return;
    }

    final listing = Listing(
      id: widget.listing?.id ?? '',
      name: _nameC.text.trim(),
      category: category,
      address: _addressC.text.trim(),
      contactNumber: _phoneC.text.trim(),
      description: _descC.text.trim(),
      latitude: double.tryParse(_latC.text) ?? -1.9536,
      longitude: double.tryParse(_lngC.text) ?? 30.0606,
      createdBy: widget.listing?.createdBy ?? user.uid,
      createdAt: widget.listing?.createdAt ?? Timestamp.now(),
    );

    final service = ref.read(listingServiceProvider);
    if (widget.listing == null) {
      await service.createListing(listing);
    } else {
      await service.updateListing(widget.listing!.id, {
        'name': listing.name,
        'category': listing.category,
        'address': listing.address,
        'contactNumber': listing.contactNumber,
        'description': listing.description,
        'latitude': listing.latitude,
        'longitude': listing.longitude,
      });
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.listing == null ? 'Create Listing' : 'Edit Listing'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameC,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => (v ?? '').isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _addressC,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              TextFormField(
                controller: _phoneC,
                decoration: const InputDecoration(labelText: 'Contact'),
              ),
              DropdownButtonFormField<String>(
                initialValue: category,
                items: const [
                  DropdownMenuItem(value: 'Hospital', child: Text('Hospital')),
                  DropdownMenuItem(value: 'Pharmacy', child: Text('Pharmacy')),
                  DropdownMenuItem(
                    value: 'Police Station',
                    child: Text('Police Station'),
                  ),
                  DropdownMenuItem(value: 'Library', child: Text('Library')),
                  DropdownMenuItem(
                    value: 'Utility Office',
                    child: Text('Utility Office'),
                  ),
                  DropdownMenuItem(
                    value: 'Restaurant',
                    child: Text('Restaurant'),
                  ),
                  DropdownMenuItem(value: 'Café', child: Text('Café')),
                  DropdownMenuItem(value: 'Park', child: Text('Park')),
                  DropdownMenuItem(
                    value: 'Tourist Attraction',
                    child: Text('Tourist Attraction'),
                  ),
                ],
                onChanged: (v) => setState(() => category = v ?? category),
              ),
              TextFormField(
                controller: _descC,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latC,
                      decoration: const InputDecoration(labelText: 'Latitude'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _lngC,
                      decoration: const InputDecoration(labelText: 'Longitude'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton(onPressed: _submit, child: const Text('Save')),
            ],
          ),
        ),
      ),
    );
  }
}
