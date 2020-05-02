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
    Pointer<FPDF_PAGE> page;
    Pointer<FPDF_DOCUMENT> doc;
    Pointer<FPDF_BITMAP> bitmap;
    Uint8List buf;

    int ppi = (MediaQuery.of(context).devicePixelRatio * 160).toInt();
    ppi = 100;
    if (widget.filePath == null) return;

    doc = loadDocument(widget.filePath);
    page = fLoadPage(doc, 0);
    int pageCount = fGetPageCount(doc);
    fPageSetRotation(page, 4);
    width = fGetPageWidth(page).toInt();
    height = fGetPageHeight(page).toInt();
    width = pointsToPixels(width, ppi).toInt();
    height = pointsToPixels(height, ppi).toInt();
    width = MediaQuery.of(context).size.width.toInt();
    height = MediaQuery.of(context).size.height.toInt();
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
