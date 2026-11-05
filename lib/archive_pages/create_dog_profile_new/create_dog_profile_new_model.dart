import '/flutter_flow/flutter_flow_util.dart';
import 'create_dog_profile_new_widget.dart' show CreateDogProfileNewWidget;
import 'package:flutter/material.dart';

class CreateDogProfileNewModel
    extends FlutterFlowModel<CreateDogProfileNewWidget> {
  ///  State fields for stateful widgets in this page.

  bool isDataUploading_uploadDataKmy = false;
  FFUploadedFile uploadedLocalFile_uploadDataKmy =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadDataKmy = '';

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
