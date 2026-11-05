import '/flutter_flow/flutter_flow_util.dart';
import 'edit_dog_profile_widget.dart' show EditDogProfileWidget;
import 'package:flutter/material.dart';

class EditDogProfileModel extends FlutterFlowModel<EditDogProfileWidget> {
  ///  State fields for stateful widgets in this page.

  bool isDataUploading_uploadDataGj1 = false;
  FFUploadedFile uploadedLocalFile_uploadDataGj1 =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadDataGj1 = '';

  // State field(s) for dogName widget.
  FocusNode? dogNameFocusNode;
  TextEditingController? dogNameTextController;
  String? Function(BuildContext, String?)? dogNameTextControllerValidator;
  // State field(s) for dogBreed widget.
  FocusNode? dogBreedFocusNode;
  TextEditingController? dogBreedTextController;
  String? Function(BuildContext, String?)? dogBreedTextControllerValidator;
  // State field(s) for dogAge widget.
  FocusNode? dogAgeFocusNode;
  TextEditingController? dogAgeTextController;
  String? Function(BuildContext, String?)? dogAgeTextControllerValidator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    dogNameFocusNode?.dispose();
    dogNameTextController?.dispose();

    dogBreedFocusNode?.dispose();
    dogBreedTextController?.dispose();

    dogAgeFocusNode?.dispose();
    dogAgeTextController?.dispose();
  }
}
