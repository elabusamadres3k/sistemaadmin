import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'create_your_profile_widget.dart' show CreateYourProfileWidget;
import 'package:flutter/material.dart';

class CreateYourProfileModel extends FlutterFlowModel<CreateYourProfileWidget> {
  ///  State fields for stateful widgets in this page.

  bool isDataUploading_uploadDataTr7 = false;
  FFUploadedFile uploadedLocalFile_uploadDataTr7 =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadDataTr7 = '';

  // State field(s) for yourName widget.
  FocusNode? yourNameFocusNode;
  TextEditingController? yourNameTextController;
  String? Function(BuildContext, String?)? yourNameTextControllerValidator;
  // State field(s) for userName widget.
  FocusNode? userNameFocusNode;
  TextEditingController? userNameTextController;
  String? Function(BuildContext, String?)? userNameTextControllerValidator;
  // State field(s) for bio widget.
  FocusNode? bioFocusNode;
  TextEditingController? bioTextController;
  String? Function(BuildContext, String?)? bioTextControllerValidator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    yourNameFocusNode?.dispose();
    yourNameTextController?.dispose();

    userNameFocusNode?.dispose();
    userNameTextController?.dispose();

    bioFocusNode?.dispose();
    bioTextController?.dispose();
  }
}
