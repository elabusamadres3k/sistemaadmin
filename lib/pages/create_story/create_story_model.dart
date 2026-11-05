import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'create_story_widget.dart' show CreateStoryWidget;
import 'package:flutter/material.dart';

class CreateStoryModel extends FlutterFlowModel<CreateStoryWidget> {
  ///  State fields for stateful widgets in this page.

  bool isDataUploading_uploadDataQ5l = false;
  FFUploadedFile uploadedLocalFile_uploadDataQ5l =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadDataQ5l = '';

  // State field(s) for storyDescription widget.
  FocusNode? storyDescriptionFocusNode;
  TextEditingController? storyDescriptionTextController;
  String? Function(BuildContext, String?)?
      storyDescriptionTextControllerValidator;
  bool isDataUploading_uploadDataNzi = false;
  FFUploadedFile uploadedLocalFile_uploadDataNzi =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadDataNzi = '';

  bool isDataUploading_uploadDataS5t = false;
  FFUploadedFile uploadedLocalFile_uploadDataS5t =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadDataS5t = '';

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    storyDescriptionFocusNode?.dispose();
    storyDescriptionTextController?.dispose();
  }
}
