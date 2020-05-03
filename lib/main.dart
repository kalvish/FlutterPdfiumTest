import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:convert' as convertlib;

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:streams_test/pdfium/pdfium.dart';

import 'package:file_picker/file_picker.dart';

//remote repo
//https://github.com/kalvish/FlutterPdfiumTest/commits/master
//useful links
//pdfium doc https://pdfium.patagames.com/help/html/M_Patagames_Pdf_Pdfium_FPDF_GetPageSizes.htm
//https://pdfium.googlesource.com/pdfium/+/refs/heads/master/samples/pdfium_test.cc
//https://pdfium.googlesource.com/pdfium/+/refs/heads/master/fpdfsdk/fpdf_view_c_api_test.c
//https://pdfium.googlesource.com/pdfium/+/master/public/fpdf_annot.h
//Utf16 example https://github.com/dart-lang/ffi/issues/35
//pdfium doc https://developers.foxitsoftware.com/resources/pdf-sdk/c_api_reference_pdfium/group___f_p_d_f_i_u_m.html#gaf31488e80db809dd21e4b0e94a266fe6
//dart:ffi samples  https://github.com/dart-lang/samples/blob/master/ffi/primitives/primitives.dart
//flutter device width height https://stackoverflow.com/questions/49553402/flutter-screen-size
//android pdfium fork with text selection and search https://github.com/kalvish/android-support-pdfium/blob/master/library/src/main/java/org/benjinus/pdfium/PdfiumSDK.java
//android pdfium pull request with text seleciton https://github.com/barteksc/PdfiumAndroid/pull/32/files
//android barteksc PDFView https://github.com/barteksc/AndroidPdfViewer/blob/master/android-pdf-viewer/src/main/java/com/github/barteksc/pdfviewer/PDFView.java
//android barteksc Pdfium Core https://github.com/barteksc/PdfiumAndroid/blob/103d5855f797af78a6f33f94cb306ef1c23b2290/src/main/java/com/shockwave/pdfium/PdfiumCore.java#L433
//dartpad custom painter sample https://dartpad.dev/a1bde55a35d88ec7d58fcd0022926ad1
//dartpad custom painter tutorial https://codewithandrea.com/videos/2020-01-27-flutter-custom-painting-do-not-fear-canvas/


void main() async {
  // See https://github.com/flutter/flutter/wiki/Desktop-shells#target-platform-override
  // debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;

  // WidgetsFlutterBinding.ensureInitialized();
  // var base = await path.getApplicationSupportDirectory();
  // loadDylib('${base.path}/debug/libpdfium.dylib');
  loadDylib('');
  initLibrary();

  runApp(new MyApp());
}

// void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // See https://github.com/flutter/flutter/wiki/Desktop-shells#fonts
        fontFamily: 'Roboto',
      ),
      home: Scaffold(
        appBar: AppBar(title: Text('Flutter Pdfium')),
        body: MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var settingsVisible = true;
  String selectedPdf;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        ExpansionPanelList(
          expansionCallback: (int index, bool isExpanded) {
            setState(() {
              settingsVisible = !settingsVisible;
            });
          },
          children: [
            ExpansionPanel(
              canTapOnHeader: true,
              headerBuilder: (context, isExpanded) {
                return ListTile(title: Text('Settings'));
              },
              body: Column(
                children: <Widget>[
                  RaisedButton(
                    child: Text('Choose PDF'),
                    onPressed: () async {
                      String selectedPath = await FilePicker.getFilePath(
                          type: FileType.ANY, fileExtension: 'pdf');
                      setState(() {
                        selectedPdf = selectedPath;
                      });
                      // showOpenPanel((result, files) {
                      //   if (files.isEmpty) return;
                      //   setState(() {
                      //     selectedPdf = files[0];
                      //   });
                      // }, allowedFileTypes: ['pdf']);
                    },
                  ),
                  Text(
                    selectedPdf ?? '',
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              isExpanded: settingsVisible,
            ),
          ],
        ),
        Container(
          child: PdfView(selectedPdf),
        ),
      ],
    );
  }
}

class PdfPainter extends CustomPainter {
  final ui.Image image;

  PdfPainter(this.image);

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    canvas.drawCircle(Offset.zero, 20.0, Paint());
    canvas.drawImage(image, Offset.zero, Paint());
  }

  @override
  bool shouldRepaint(PdfPainter oldDelegate) {
    return oldDelegate.image != image;
  }
}

class PdfView extends StatefulWidget {
  final String filePath;

  PdfView(this.filePath);

  @override
  _PdfViewState createState() => _PdfViewState();
}

class _PdfViewState extends State<PdfView> {
  ui.Image image;

  @override
  void didUpdateWidget(PdfView oldWidget) {
    int width;
    int height;
    int deviceWidth;
    int deviceHeight;
    Pointer<FPDF_PAGE> page;
    Pointer<FPDF_DOCUMENT> doc;
    Pointer<FPDF_BITMAP> bitmap;
    Uint8List buf;

    int ppi = (MediaQuery.of(context).devicePixelRatio * 160).toInt();
    // ppi = 100;
    if (widget.filePath == null) return;

    doc = loadDocument(widget.filePath);
    page = fLoadPage(doc, 0);
    int pageCount = fGetPageCount(doc);
    fPageSetRotation(page, 4);
    width = fGetPageWidth(page).toInt();
    height = fGetPageHeight(page).toInt();
    width = pointsToPixels(width, ppi).toInt();
    height = pointsToPixels(height, ppi).toInt();
    deviceWidth = MediaQuery.of(context).size.width.toInt();
    deviceHeight = MediaQuery.of(context).size.height.toInt();
    bitmap = fBitmapCreate(width, height, 1);
    fBitmapFillRect(bitmap, 0, 0, width, height, 0);
    fRenderPageBitmap(bitmap, page, 0, 0, width, height, 0, 0);

    buf = fBitmapGetBuffer(bitmap)
        .asTypedList(width * height)
        .buffer
        .asUint8List();

    ui.decodeImageFromPixels(
      buf,
      width,
      height,
      ui.PixelFormat.bgra8888,
      (img) {
        setState(() {
          image = img;
        });
      },
    );

/*
Load FPDF_TEXTPAGE from a FPDF_PAGE
*/
    Pointer<FPDF_TEXTPAGE> fpdf_textpage = fTextLoadPage(page);
    int error = fGetLastError();

/*
Check if the input annotation type available or not.
*/
    int isTextAvailable = fAnnotIsSupportedSubtype(1);
    /*
    If fGetLastError returns 0, it means the method request was successful.
    */
    int errorFAnnotIsSupportedSubtype = fGetLastError();
    // Pointer<Utf8> extracted_text = fTextGetText(fpdf_textpage,1,3);
    // int errorFTextGetText = fGetLastError();
    /*
    Get text count on a FPDF_TEXTPAGE
    */
    int textCountOnPage = fTextCountChars(fpdf_textpage);
    List<int> textList = new List();
    for (var i = 0; i < 100; i++) {
      /*
      Get unicode character for each character in a FPDF_TEXTPAGE
      */
      int textUnicode = fTextGetUnicode(fpdf_textpage, i);
      textList.add(textUnicode);

      // print(textUnicode);
    }
    List<int> textListTemp = new List();
    textListTemp.add(101);
    textListTemp.add(83);
    var dec = convertlib.utf8.decode(textList);
    print(dec);

    int countNoOfRectAreas = fTextCountRects(fpdf_textpage, 0, 100);
    int errorFTextCountRects = fGetLastError();

    //allocate made it work.
    Pointer<Double> leftP = allocate<Double>();
    Pointer<Double> rightP = allocate<Double>();
    Pointer<Double> bottomP = allocate<Double>();
    Pointer<Double> topP = allocate<Double>();
    fTextGetCharBox(fpdf_textpage, 0, leftP, rightP, bottomP, topP);
    int errorFTextGetCharBox = fGetLastError();
    /*
    Close FPDF_TEXTPAGE after all related operations
    */
    fTextClosePage(fpdf_textpage);
    int errorFTextClosePage = fGetLastError();

    // String test = extracted_text.toString();
    // String text = Utf8.fromUtf8(extracted_text);

    fCloseDocument(doc);

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.filePath == null) {
      return Container();
    }
    if (image == null) {
      return CircularProgressIndicator();
    }
    return CustomPaint(
      painter: PdfPainter(image),
    );
  }
}
