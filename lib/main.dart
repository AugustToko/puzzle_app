import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_extend/share_extend.dart';
import 'package:tuple/tuple.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<Tuple2<String, double>> images = [];

  final screenshotController = ScreenshotController();

  final imagePicker = ImagePicker();

  var vertical = true;

  var alignment = Alignment.center;

  double quality = 4;

  @override
  Widget build(BuildContext context) {
    final imageWidgets = List.generate(images.length, (index) {
      return Stack(
        children: [
          Transform.rotate(
            angle: math.pi / 180 * images[index].item2,
            child: Image.file(
              File(images[index].item1),
              filterQuality: FilterQuality.high,
            ),
          ),
          Positioned.fill(
              child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      showImageOptDialog(index);
                    },
                  )))
        ],
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('缝合怪 ${images.length} 张'),
        actions: [
          IconButton(
              icon: Icon(Icons.photo_filter_rounded),
              tooltip: '设置图片质量',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    var temp = '4.0';
                    return AlertDialog(
                      title: Text('设置图片质量'),
                      content: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            onChanged: (str) {
                              temp = str;
                            },
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                                hintText: '质量不宜过大，建议 1 ~ 8，默认为 4'),
                          ),
                          SizedBox(height: 16),
                          Text('当前质量: ${quality.toDouble().toString()}')
                        ],
                      ),
                      actions: [
                        FlatButton(
                            onPressed: () {
                              quality = 4.0;
                              Navigator.pop(context);
                            },
                            child: Text('恢复默认')),
                        FlatButton(
                            onPressed: () {
                              if (temp != null && temp.trim().isNotEmpty) {
                                quality = double.tryParse(temp);
                              }
                              Navigator.pop(context);
                            },
                            child: Text('设定')),
                      ],
                    );
                  },
                );
              }),
          IconButton(
              icon: Icon(getAlignmentIcon()),
              tooltip: '对齐',
              onPressed: () {
                setState(() {
                  setState(() {
                    if (alignment == Alignment.topCenter) {
                      alignment = Alignment.center;
                      return;
                    }

                    if (alignment == Alignment.center) {
                      alignment = Alignment.bottomCenter;
                      return;
                    }

                    if (alignment == Alignment.bottomCenter) {
                      alignment = Alignment.topCenter;
                      return;
                    }
                  });
                });
              }),
          IconButton(
              icon: Icon(Icons.rotate_left),
              tooltip: '切换垂直或水平',
              onPressed: () {
                setState(() {
                  vertical = !vertical;
                });
              }),
          IconButton(
              icon: Icon(Icons.add),
              tooltip: '添加照片',
              onPressed: () async {
                final image =
                    await imagePicker.getImage(source: ImageSource.gallery);
                if (image == null) return;
                setState(() {
                  images.add(Tuple2(image.path, 0));
                });
              }),
        ],
      ),
      body: SingleChildScrollView(
        scrollDirection: vertical ? Axis.vertical : Axis.horizontal,
        child: Screenshot(
          controller: screenshotController,
          child: vertical
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: imageWidgets,
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: getAlignmentRow(),
                  children: imageWidgets,
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: '缝合!',
        onPressed: () {
          if (images.isEmpty) return;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return AlertDialog(
                title: Text('缝合中...'),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text('如果等待时间过长，退出app重试。')
                  ],
                ),
              );
            },
          );

          screenshotController
              .capture(pixelRatio: quality.toDouble())
              .then((image) {
            Navigator.pop(context);
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text('选择操作方式'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: Text('分享'),
                        onTap: () {
                          ShareExtend.share(image.path, 'image');
                        },
                      ),
                      ListTile(
                        title: Text('保存'),
                        onTap: () async {
                          final folder = await getExternalStorageDirectory();
                          final target =
                              File('${folder.path}/${DateTime.now()}.png');
                          target.writeAsBytes(image.readAsBytesSync());
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text('保存成功'),
                                content: Text('保存至: ${target.path}'),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                  actions: [],
                );
              },
            );
          }).catchError((onError) {
            Navigator.pop(context);
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text('出现错误！'),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [Text('$onError\n可能原因：图片过多或图片过大')],
                  ),
                );
              },
            );
            print(onError);
          });
        },
        child: Icon(Icons.image),
      ),
    );
  }

  void showImageOptDialog(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('图片选项'),
          content: SingleChildScrollView(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  title: Text('旋转 0°'),
                  onTap: () {
                    setState(() {
                      images[index] = Tuple2(images[index].item1, 0);
                    });
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: Text('旋转 90°'),
                  onTap: () {
                    setState(() {
                      images[index] = Tuple2(images[index].item1, 90);
                    });
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: Text('旋转 180°'),
                  onTap: () {
                    setState(() {
                      images[index] = Tuple2(images[index].item1, 180);
                    });
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: Text('旋转 270°'),
                  onTap: () {
                    setState(() {
                      images[index] = Tuple2(images[index].item1, 270);
                    });
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: Text('删除'),
                  onTap: () {
                    setState(() {
                      images.removeAt(index);
                    });
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  CrossAxisAlignment getAlignmentRow() {
    if (alignment == Alignment.center) {
      return CrossAxisAlignment.center;
    }

    if (alignment == Alignment.topCenter) {
      return CrossAxisAlignment.start;
    }

    if (alignment == Alignment.bottomCenter) {
      return CrossAxisAlignment.end;
    }
    return null;
  }

  IconData getAlignmentIcon() {
    if (alignment == Alignment.center) {
      return Icons.vertical_align_center_rounded;
    }

    if (alignment == Alignment.topCenter) {
      return Icons.vertical_align_top_rounded;
    }

    if (alignment == Alignment.bottomCenter) {
      return Icons.vertical_align_bottom_rounded;
    }
    return null;
  }
}
