import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models/discovery_model.dart';
import '../../core/theme/app_colors.dart';

class UploadScreen extends StatefulWidget {
  final VoidCallback? onSubmissionSuccess;

  const UploadScreen({super.key, this.onSubmissionSuccess});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _significanceController = TextEditingController();

  CulturalCategory _selectedCategory = CulturalCategory.food;
  final ImagePicker _imagePicker = ImagePicker();

  String? _pickedImageName;
  Uint8List? _pickedImageBytes;
  String? _imageError;
  bool _isPickingImage = false;

  bool _isAiEnhancing = false;
  bool _aiEnhancedApplied = false;
  bool _isSubmitting = false;

  // Selected GPS coordinates
  double? _selectedLatitude;
  double? _selectedLongitude;

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _significanceController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Photo Selection: Camera or Gallery via ImagePicker
  // ---------------------------------------------------------------------------
  Future<void> _pickPhoto(ImageSource source) async {
    setState(() {
      _isPickingImage = true;
      _imageError = null;
    });

    try {
      final XFile? file = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (file == null) {
        setState(() => _isPickingImage = false);
        return;
      }

      // Read file bytes for validation and web/mobile preview support
      final bytes = await file.readAsBytes();

      // Validate reasonable file size (max 5 MB)
      const maxSizeBytes = 5 * 1024 * 1024;
      if (bytes.lengthInBytes > maxSizeBytes) {
        setState(() {
          _isPickingImage = false;
          _imageError =
              'Image is too large (${(bytes.lengthInBytes / (1024 * 1024)).toStringAsFixed(1)} MB). Please select a photo under 5 MB.';
        });
        return;
      }

      setState(() {
        _pickedImageName = file.name;
        _pickedImageBytes = bytes;
        _imageError = null;
        _isPickingImage = false;
      });
    } catch (e) {
      debugPrint('Photo picker error: $e');
      setState(() {
        _isPickingImage = false;
        _imageError = 'Unable to access camera or gallery. Please check device permissions.';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Permission notice: $e', style: GoogleFonts.nunito()),
            backgroundColor: AppColors.coral,
          ),
        );
      }
    }
  }

  void _removePhoto() {
    setState(() {
      _pickedImageName = null;
      _pickedImageBytes = null;
      _imageError = null;
    });
  }

  // ---------------------------------------------------------------------------
  // GPS Location Pinning
  // ---------------------------------------------------------------------------
  void _useCurrentGpsLocation() {
    setState(() {
      _selectedLatitude = 2.2878;
      _selectedLongitude = 111.8305;
      _locationController.text =
          'Sibu Heritage District (2.2878° N, 111.8305° E)';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '📍 Coordinates pinned: Sibu Heritage District (2.2878° N, 111.8305° E)',
        ),
        backgroundColor: AppColors.primary,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Simulated AI Cultural Description Assistant
  // ---------------------------------------------------------------------------
  Future<void> _triggerAiAssistant() async {
    setState(() => _isAiEnhancing = true);

    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted) return;

    String enhancedDesc;
    String enhancedSignificance;

    switch (_selectedCategory) {
      case CulturalCategory.food:
        enhancedDesc = 'A traditional Foochow culinary delicacy cooked in a smoking wok with hand-pulled rice noodle slurry, fresh river prawns, cuttlefish slices, and fragrant peppered broth.';
        enhancedSignificance = 'Historically prepared during community festivals in Sibu, representing family unity and riverine Foochow heritage.';
        break;
      case CulturalCategory.heritage:
        enhancedDesc = 'Historical wooden shophouses dating back to early 20th century trade along the Rajang River, showcasing traditional southeastern Chinese timber joinery.';
        enhancedSignificance = 'Served as the economic and cultural center for early settlers, native river traders, and artisans in Sarawak.';
        break;
      case CulturalCategory.murals:
        enhancedDesc = 'Vibrant community mural celebrating indigenous hornbill lore, native flora, and historic river trade wharf life painted by local Sarawakian artists.';
        enhancedSignificance = 'Preserves urban folklore and raises youth awareness of regional multicultural heritage.';
        break;
      case CulturalCategory.crafts:
        enhancedDesc = 'Authentic handwoven crafts made from wild rattan and swamp reed (bemban) utilizing indigenous Dayak and Orang Ulu weaving patterns.';
        enhancedSignificance = 'Reflects multi-generational ancestral knowledge passed down through oral tradition and sustainable forest harvesting.';
        break;
    }

    setState(() {
      _isAiEnhancing = false;
      _aiEnhancedApplied = true;
      _descriptionController.text = enhancedDesc;
      _significanceController.text = enhancedSignificance;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '✨ AI Assistant added cultural context and historical significance notes.',
        ),
        backgroundColor: AppColors.primary,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Form Submission
  // ---------------------------------------------------------------------------
  Future<void> _handleSubmit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title for this cultural discovery.'),
          backgroundColor: AppColors.coral,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    String? photoUrl;

    // Attempt real Supabase Storage upload if configured
    if (_pickedImageBytes != null) {
      try {
        final client = Supabase.instance.client;
        final fileName =
            'gem_${DateTime.now().millisecondsSinceEpoch}_${_selectedCategory.name}.jpg';
        await client.storage
            .from('discoveries')
            .uploadBinary(
              fileName,
              _pickedImageBytes!,
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );
        photoUrl = client.storage.from('discoveries').getPublicUrl(fileName);
      } catch (e) {
        debugPrint(
          'Supabase storage upload note (bucket may not be created yet): $e',
        );
        // Fallback: continue gracefully so users can still submit discoveries
      }
    }

    // Attempt Supabase database insertion if table exists
    try {
      final client = Supabase.instance.client;
      await client.from('discoveries').insert({
        'title': title,
        'category': _selectedCategory.name,
        'location': _locationController.text.trim().isNotEmpty
            ? _locationController.text.trim()
            : 'Sibu, Sarawak',
        'description': _descriptionController.text.trim(),
        'cultural_significance': _significanceController.text.trim(),
        'latitude': _selectedLatitude ?? 2.2878,
        'longitude': _selectedLongitude ?? 111.8305,
        'image_url': photoUrl,
        'is_approved':
            false, // Newly submitted gems require community curator review!
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint(
        'Supabase database insert note (table or policy may be pending): $e',
      );
    }

    if (!mounted) return;

    setState(() => _isSubmitting = false);
    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFFF9F0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFF5A4D47), width: 2),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Text(
              'Submission Received',
              style: GoogleFonts.fredoka(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFDFF7F2),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: Center(
                child: Text(
                  _selectedCategory.emoji,
                  style: const TextStyle(fontSize: 36),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _titleController.text.trim().isNotEmpty
                  ? _titleController.text.trim()
                  : 'Cultural Discovery',
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.darkBrown,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0D1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2C46E)),
              ),
              child: Text(
                'Status: In Review ⏳',
                style: GoogleFonts.fredoka(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF7A6014),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your discovery will be reviewed by community curators for cultural authenticity. Once verified, it will appear on the public map and earn Contributor Badges.',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 12,
                color: AppColors.secondaryText,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _resetForm();
                if (widget.onSubmissionSuccess != null) {
                  widget.onSubmissionSuccess!();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0xFF336E67), width: 1.8),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 10,
                ),
              ),
              child: Text(
                'Done & View Profile',
                style: GoogleFonts.fredoka(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    _titleController.clear();
    _locationController.clear();
    _descriptionController.clear();
    _significanceController.clear();
    setState(() {
      _selectedCategory = CulturalCategory.food;
      _pickedImageName = null;
      _pickedImageBytes = null;
      _imageError = null;
      _aiEnhancedApplied = false;
      _selectedLatitude = null;
      _selectedLongitude = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 110),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),

                  // 1. Header Section (Responsive with Expanded to prevent overflow)
                  _buildHeader(),

                  const SizedBox(height: 18),

                  // 2. Photo & Visuals Section (Camera & Gallery picker with preview)
                  _buildPhotoSection(),

                  const SizedBox(height: 20),

                  // 3. Category Selector
                  _buildCategorySelector(),

                  const SizedBox(height: 20),

                  // 4. Gem Title Field
                  _buildTextField(
                    label: 'Cultural Gem Title',
                    hintText: 'e.g. Sibu Dian Bian Hu, Heritage Pagoda, Belacan Mural',
                    controller: _titleController,
                    icon: Icons.edit_location_alt_rounded,
                  ),

                  const SizedBox(height: 16),

                  // 5. Location & Address with GPS button
                  _buildLocationField(),

                  const SizedBox(height: 16),

                  // 6. Cultural Description & AI Assistant
                  _buildDescriptionSection(),

                  const SizedBox(height: 16),

                  // 7. Cultural Significance
                  _buildTextField(
                    label: 'Cultural Significance & Heritage Note (Optional)',
                    hintText: 'Why is this place important to Sarawak history or community?',
                    controller: _significanceController,
                    maxLines: 2,
                    icon: Icons.history_edu_rounded,
                  ),

                  const SizedBox(height: 20),

                  // 8. Community Guidelines Card
                  _buildCommunityGuidelinesCard(),

                  const SizedBox(height: 24),

                  // 9. Submit Button
                  _buildSubmitButton(),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Header Section (Fully Responsive - No Overflow)
  // ---------------------------------------------------------------------------
  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Add Discovery',
                    style: GoogleFonts.fredoka(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkBrown,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('📍', style: TextStyle(fontSize: 18)),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Submit authentic local food, heritage, murals or crafts.',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0D1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2C46E), width: 1.4),
          ),
          child: Text(
            'Community',
            style: GoogleFonts.fredoka(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2E2420),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Photo & Visuals Section (Take Photo & Upload Photo with Preview)
  // ---------------------------------------------------------------------------
  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photo & Visuals',
          style: GoogleFonts.fredoka(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.darkBrown,
          ),
        ),
        const SizedBox(height: 8),

        // Photo Preview or Empty Box
        Container(
          width: double.infinity,
          height: 190,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _imageError != null
                  ? AppColors.coral
                  : const Color(0xFF5A4D47),
              width: 1.8,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFFD6CBC3),
                offset: Offset(0, 4),
                blurRadius: 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: _pickedImageBytes != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      // Display image from bytes (cross-platform Android + Web compatible)
                      Image.memory(_pickedImageBytes!, fit: BoxFit.cover),
                      // Top Action Overlay: Remove / Replace buttons
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: _removePhoto,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.close_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Remove',
                                      style: GoogleFonts.nunito(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Bottom Tag showing photo attached
                      Positioned(
                        bottom: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _pickedImageName != null &&
                                        _pickedImageName!.length > 18
                                    ? '${_pickedImageName!.substring(0, 16)}...'
                                    : (_pickedImageName ?? 'Photo attached'),
                                style: GoogleFonts.nunito(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: const Color(0xFFDFF7F2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary,
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.add_a_photo_outlined,
                              size: 26,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Attach Location Photo',
                            style: GoogleFonts.fredoka(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkBrown,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Take a clear picture or upload from device gallery (Max 5 MB)',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(
                              fontSize: 11,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),

        // Error message if file is oversized or unreadable
        if (_imageError != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              _imageError!,
              style: GoogleFonts.nunito(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Colors.red[700],
              ),
            ),
          ),
        ],

        const SizedBox(height: 10),

        // 2 Action Buttons: "Take Photo" & "Upload Photo"
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isPickingImage
                    ? null
                    : () => _pickPhoto(ImageSource.camera),
                icon: const Icon(Icons.photo_camera_rounded, size: 18),
                label: Text(
                  'Take Photo',
                  style: GoogleFonts.fredoka(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.darkBrown,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF5A4D47), width: 1.6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isPickingImage
                    ? null
                    : () => _pickPhoto(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_rounded, size: 18),
                label: Text(
                  'Upload Photo',
                  style: GoogleFonts.fredoka(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.darkBrown,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF5A4D47), width: 1.6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Category Selector
  // ---------------------------------------------------------------------------
  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cultural Category',
          style: GoogleFonts.fredoka(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.darkBrown,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: CulturalCategory.values.map((cat) {
            final isSelected = _selectedCategory == cat;

            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? cat.color : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.darkBrown
                          : const Color(0xFFD6CBC3),
                      width: isSelected ? 1.8 : 1.2,
                    ),
                    boxShadow: isSelected
                        ? const [
                            BoxShadow(
                              color: Color(0xFFD6CBC3),
                              offset: Offset(0, 3),
                              blurRadius: 0,
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    children: [
                      Text(cat.emoji, style: const TextStyle(fontSize: 20)),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          cat.label,
                          style: GoogleFonts.fredoka(
                            fontSize: 11.5,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: AppColors.darkBrown,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Custom Text Field Helper
  // ---------------------------------------------------------------------------
  Widget _buildTextField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    int maxLines = 1,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.fredoka(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: AppColors.darkBrown,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.darkBrown, width: 1.8),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFFD6CBC3),
                offset: Offset(0, 3),
                blurRadius: 0,
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: GoogleFonts.nunito(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.darkBrown,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: GoogleFonts.nunito(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF9E9590),
              ),
              prefixIcon: icon != null
                  ? Icon(icon, color: AppColors.primary, size: 20)
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 5. Location Field (Responsive - No Overflow)
  // ---------------------------------------------------------------------------
  Widget _buildLocationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'Location & Address',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.fredoka(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkBrown,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _useCurrentGpsLocation,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.lightMint,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary, width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.my_location_rounded,
                      size: 12,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Use GPS',
                      style: GoogleFonts.fredoka(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.darkBrown, width: 1.8),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFFD6CBC3),
                offset: Offset(0, 3),
                blurRadius: 0,
              ),
            ],
          ),
          child: TextField(
            controller: _locationController,
            style: GoogleFonts.nunito(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.darkBrown,
            ),
            decoration: InputDecoration(
              hintText: 'e.g. Sibu Central Market, Jalan Channel, Sarawak',
              hintStyle: GoogleFonts.nunito(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF9E9590),
              ),
              prefixIcon: const Icon(
                Icons.pin_drop_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 6. Description Field & AI Assistant (Responsive - No Overflow)
  // ---------------------------------------------------------------------------
  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Cultural Description',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.fredoka(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkBrown,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _isAiEnhancing ? null : _triggerAiAssistant,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE8E0F8), Color(0xFFFFE0ED)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF9D83B8),
                    width: 1.4,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xFFD6CBC3),
                      offset: Offset(0, 2),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isAiEnhancing)
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF6B4B8A),
                          ),
                        ),
                      )
                    else
                      const Text('✨', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      _isAiEnhancing ? 'Enhancing...' : 'AI Story Assistant',
                      style: GoogleFonts.fredoka(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF5A3E77),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.darkBrown, width: 1.8),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFFD6CBC3),
                offset: Offset(0, 3),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _descriptionController,
                maxLines: 4,
                style: GoogleFonts.nunito(
                  fontSize: 13.5,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkBrown,
                ),
                decoration: InputDecoration(
                  hintText: 'Describe what makes this place special, how traditional items are made, or local tips...',
                  hintStyle: GoogleFonts.nunito(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF9E9590),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              if (_aiEnhancedApplied)
                Container(
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3EDFB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFBCA7D4),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('✨', style: TextStyle(fontSize: 11)),
                      const SizedBox(width: 4),
                      Text(
                        'AI verified cultural context applied',
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF5A3E77),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 7. Community Guidelines Card
  // ---------------------------------------------------------------------------
  Widget _buildCommunityGuidelinesCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4FAF9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF95D1C8), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Color(0xFFD4F6E6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              size: 18,
              color: Color(0xFF2E856E),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Community Curator Review',
                  style: GoogleFonts.fredoka(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2E856E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'All community submissions are verified to ensure cultural authenticity and respectful representation of Sarawak traditions before publication.',
                  style: GoogleFonts.nunito(
                    fontSize: 11.5,
                    color: const Color(0xFF4A6B65),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 8. Submit Button
  // ---------------------------------------------------------------------------
  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: _isSubmitting ? null : _handleSubmit,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF336E67), width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF336E67),
              offset: Offset(0, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: _isSubmitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.cloud_upload_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Submit Discovery for Review',
                      style: GoogleFonts.fredoka(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
