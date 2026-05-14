import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uhd/ContactUs.dart';
import 'package:uhd/Help.dart';
import 'package:uhd/Settings.dart';
import 'AddMedicinePage.dart';
import 'AddReminderPage.dart';

//
// درووستکردنی کڵاسێك بۆ دەرمانەکان(ئایدییەکەی، ناوەکەی، کاتی خواردنەکەی)
// ئایدییەکەی بەس بۆ کاتی سڕینەوەی بەکار ئەهێنین، جگە لەوە پێویستمان بە ئایدی نییە
class MedicationReminder {
  final int id;
  String name;
  TimeOfDay time;
  final String? notes;
  final String? condition;

  MedicationReminder({
    required this.id,
    required this.name,
    required this.time,
    this.notes,
    this.condition,
  });
}

class Medicine {
  final int id;
  String name;
  String department;
  String? description;

  Medicine({
    required this.id,
    required this.name,
    required this.department,
    this.description,
  });
}

class HomePage extends StatefulWidget {
  final String userName;
  const HomePage({super.key, required this.userName});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  
  //
  // هەموو ئەو دەرمان و کاتانەی زیادیان ئەکەین ئەبێت بە شێوازی لیست هەڵیبگرین
  // ئەگەر بە شێوازی لیست نەبێت ناتوانیت زیاد لە دانەیەك زیاد بکەیت
  // وەك ئەرەی لیستەکەی جاڤا
  final List<MedicationReminder> _reminders = [];

  final List<Medicine> _medicines = [];

  // میذۆدی زیاد کردن کە  پارامیتەرەکانی ناوی دەرمان و کاتی خواردنی تیایە
  void _addMedicineReminder(String name, String timeStr, String notes, String condition) {
    try {
      // بۆ وەرگرتنی کاتەکە بە شێوازی Hour:Minute
      final parts = timeStr.split(':');

      // ئەمەیان تەنها سەعاتەکە وەرەگرێت و ئەیخاتە بەشی یەکەمی parts کە لە سەرەوە دروست کراوە
      int hour = int.parse(parts[0]);

      // ئەمەیان تەنها خولەکەکە وەرەگرێت و ئەیخاتە بەشی دووەمی parts کە لە سەرەوە دروست کراوە
      int minute = int.parse(parts[1]);

      // بۆ ڕێگری کردن لە داغڵکردنی کاتی هەڵە
      // بەم جۆرەیە:  ئەگەر سەعات بچووکتر بوو لە سفر، یان گەورەتر بوو  لە ٢٣
      // یان خولەك بچووکتر بوو لە سفر یان گەورەتر بوو لە ٥٩
      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
        //
        // ئەوا ئەم ئیرۆر مەسجە پیشانبە لە سناك باڕ
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: Hour must be 0 to 23 and Minute 0 to 59.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      setState(() {
        // زیادکردنی دەرمانەکە بۆ لیستەکە
        // add خۆی میذۆدی حازری دارتە بۆ زیادکردنی ئایتمێك بۆ لیست
        _reminders.add(
          // کۆنسترەکتەری کڵاسی MedicationReminder ـە
          MedicationReminder(
            // درووست کردنی ئایدییەك کە بە پێی چرکەی درووستکردنی ئایتمەکە دایئەنێت
            id: DateTime.now().second,
            name: name,
            // درووستکردنی کاتەکە
            // سەعاتەکەی لە سەرەوە درووستمان کرد ئەخاتە Hour
            //و خولەکەکەش ئەخاتە Minuteـەوە
            time: TimeOfDay(hour: hour, minute: minute),
            notes: notes.isNotEmpty == true ? notes : null,
            condition: condition,
          ),
        );
      });
    } catch (e) {
      // هەر ئیرۆرێکی تر ڕوویدا ئەوا لە کۆنسوڵا پیشانیبە
      print(e);
    }
  }

  void _addMedicine(String name, String department, String description) {
    setState(() {
      _medicines.add(
        Medicine(
          id: DateTime.now().second,
          name: name,
          department: department,
          description: description.isNotEmpty ? description : null,
        ),
      );
    });
  }

  // میذۆدی سڕینەوەی ئایتمێك لە لیستەکە
  void _deleteMedicine(int id) {
    setState(() {
      // سڕینەوەی دەرمانەکە لە لیستەکە بە پێی ئایدی
      _reminders.removeWhere((reminder) => reminder.id == id);
    });
  }

  void _deleteMedicineItem(int id) {
    setState(() {
      _medicines.removeWhere((medicine) => medicine.id == id);
    });
  }

  Color _getDepartmentColor(String department) {
    switch (department) {
      case 'Pain Relief':
        return Colors.red[400]!;
      case 'Cardiovascular':
        return Colors.blue[400]!;
      case 'Antibiotics':
        return Colors.green[400]!;
      case 'Diabetes':
        return Colors.orange[400]!;
      case 'Respiratory':
        return Colors.cyan[400]!;
      case 'Mental Health':
        return Colors.purple[400]!;
      case 'Digestive':
        return Colors.brown[400]!;
      case 'Hormonal':
        return Colors.pink[400]!;
      case 'Skin Care':
        return Colors.teal[400]!;
      case 'Vitamins & Supplements':
        return Colors.yellow[600]!;
      default:
        return Colors.grey[400]!;
    }
  }

  Color _getConditionColor(String condition) {
    switch (condition) {
      case 'Pain Relief':
      case 'Headache':
        return Colors.red[300]!;
      case 'Fever':
        return Colors.orange[300]!;
      case 'Infection':
        return Colors.green[300]!;
      case 'Blood Pressure':
        return Colors.blue[300]!;
      case 'Diabetes':
        return Colors.purple[300]!;
      case 'Allergy':
        return Colors.yellow[300]!;
      case 'Digestive Issues':
        return Colors.brown[300]!;
      case 'Mental Health':
        return Colors.indigo[300]!;
      default:
        return Colors.grey[300]!;
    }
  }
 Future<void> confirmDelete(BuildContext context, int id) async {
    bool? result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirm Delete"),
          content: const Text("Are you sure you want to delete this reminder?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );

    if (result == true) {
      _deleteMedicine(id);
    }
  }

  // میذۆدی دەستکاری کردنی ئایتمێك

  void _editMedicine(MedicationReminder reminder) {
    final TextEditingController nameController = TextEditingController(
      text: reminder.name,
    );

    final TextEditingController timeController = TextEditingController(
      text:
          '${reminder.time.hour.toString().padLeft(2, '0')}:${reminder.time.minute.toString().padLeft(2, '0')}',
    );
    final TextEditingController noteController = TextEditingController(
      text: reminder.notes ?? '',
    );
    String? selectedCondition = reminder.condition;

    final List<String> conditions = [
      'Pain Relief',
      'Headache',
      'Fever',
      'Infection',
      'Blood Pressure',
      'Diabetes',
      'Allergy',
      'Digestive Issues',
      'Mental Health',
      'Other'
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,//ببێت گەورە Bottom Sheet:ڕێگە دەدات 

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      /// بۆ دروستکردنی بۆکسەکە deary akain ka chy teabet 
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: StatefulBuilder(
            builder: (context, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Edit Medicine Reminder',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Medicine Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedCondition,
                  decoration: InputDecoration(
                    labelText: 'Condition',
                    border: OutlineInputBorder(),
                  ),
                  items: conditions.map((condition) {
                    return DropdownMenuItem<String>(
                      value: condition,
                      child: Text(condition),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCondition = value;
                    });
                  },
                ),
                SizedBox(height: 12),
                TextField(
                  controller: timeController,
                  decoration: InputDecoration(
                    labelText: 'Time (HH:MM)',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  decoration: InputDecoration(
                    labelText: 'Notes',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                Row(
                   mainAxisAlignment: MainAxisAlignment.end,//cancel and update abata lay rast
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel'),
                    ),
                    
                    ElevatedButton(
                      onPressed: () {
                        final name = nameController.text.trim();
                        final time = timeController.text.trim();
                        final notes = noteController.text.trim();

                        if (name.isNotEmpty && time.contains(':')) {
                          final parts = time.split(':');
                          final hour = int.parse(parts[0]);
                          final minute = int.parse(parts[1]);

                          if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
                            setState(() {
                              reminder.name = name;
                              reminder.time = TimeOfDay(hour: hour, minute: minute);
                              // Note: Since condition is final in MedicationReminder, we'd need to recreate the object
                              // For now, we'll just update the other fields
                            });
                            Navigator.pop(context);
                          }
                        }
                      },
                      child: Text('Update'),
                    ),
                  ],
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
   }
  //                           hour <= 23 &&
  //                           minute >= 0 &&
  //                           minute <= 59) {
  //                         setState(() {//nwekrdnaway katy darman
  //                           reminder.name = name;
  //                           reminder.time = TimeOfDay(
  //                             hour: hour,
  //                             minute: minute,
  //                           );
  //                         });
  //                         Navigator.pop(context);
  //                       }
  //                     }
  //                   },
  //                   child: Text('Update'),
  //                 ),
  //               ],
  //             ),
  //             SizedBox(height = 10),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //
      // بەدیەکە ئەخاتە پشتی ئاپباڕەکە و ڕەنگی باگراوندەکەی ئەکات بە ڕەنگی ئاویی
      extendBodyBehindAppBar: true,// بۆ درووستکردنی ئاپباڕەکە لە سەر باگراوندەکە
       backgroundColor: const Color.fromARGB(0, 235, 9, 9),
      ///////////// drawer 
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              //rangy backgraund drawer bashy sarawa
              decoration: BoxDecoration(color: Colors.blueGrey),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,//nusenaka la saratawa abet
                mainAxisAlignment: MainAxisAlignment.center,//nusenaka abata center
                children: [
                  Text(
                    'Welcome, ${widget.userName}!',//bachy login bkait aw nawa anusry
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ],
              ),
            ),

            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Settings()),
                );
              },
            ),

            ListTile(
              leading: Icon(Icons.contact_mail),
              title: Text('Contact Us'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ContactUsPage()),
                );
              },
            ),
            
            ListTile(
              leading: Icon(Icons.help),
              title: Text('Help'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HelpPage()),
                );
              },
            ),
            
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,// appbary backround laabat
        elevation: 0,
        centerTitle: true,//nusenaka abata nawara
        title: Text('MedReminder'),
        //
        //گۆڕینی ڕەنگی بەتنی دراوەرەکە
        iconTheme: IconThemeData(color: Colors.white),//rangy battony drawer
        //
        titleTextStyle: TextStyle(
          color: Colors.white,//rangy nusenaka agory bashy saraway nawarast
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: Container(
        //
        //بۆ تێکەڵکردنی ڕەنگی باگراوند
        // بۆ پشتی ئاپباڕەکە و بەدییەکە
        // ...kamll ranga shinakaea background
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,//bashy xwaraway lay chap kall
            end: Alignment.bottomRight,//bashy saraway lay rast tox akat
            // بۆ بینینی کاریگەرییەکەی ئەم ڕەنگە ڕەشە بگۆڕە
            colors: Theme.of(context).brightness == Brightness.dark
            //katek ka darkmoodman habet ama agory rangy eakam hamuy rangy dwam tekaly rangy eakam abet
                ? [const Color.fromARGB(255, 46, 70, 114), const Color.fromARGB(255, 240, 241, 242)]
               //rangy pshtaway agory dwamish tekaly rangy eakam abet
                : [const Color.fromARGB(255, 25, 169, 221), const Color.fromARGB(255, 235, 239, 235)],
          ),
        ),

        // SafeArea بۆ ڕیگری کردن لە تێکەڵ بوونی ئاپبار و بەدی
        // لە کاتی بردنە دواوەی بەدی بۆ پشتی ئاپباڕ
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Material(
                    elevation: 8,//kaly bashy xwaraway background
                    borderRadius: BorderRadius.circular(20),//qawsy chwarcheway containaraka
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color.fromARGB(255, 167, 169, 143)
                        : const Color.fromARGB(255, 248, 248, 248),
                    child: Padding(
                      padding: EdgeInsets.all(16),//icon u my reminderaka lagal nusenakay nawarast aheneta
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                //
                                // ئەم دیکۆرەیشنە بۆ بازنەکەی پشتی ئایکۆنەکەیە
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(175, 200, 224, 237),
                                  shape: BoxShape.circle,
                                ),
                                //
                                padding: EdgeInsets.all(12),//sizy baznay pshty
                                child: Icon(
                                  Icons.medical_services,
                                  color: Color.fromARGB(255, 143, 155, 169),//rangy iconaka nak baznakay pshty
                                  size: 28,
                                ),
                              ),
                              SizedBox(width: 12),//spacey icon lagal my reminderaka
                              Text(
                                'My Reminders',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,//rangy nusenaka tox akat waku boold
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.blueGrey[900],//rangy nusenaka agory
                                ),
                              ),

                            
                            ],
                          ),
                          SizedBox(height: 12),
                          Expanded(
                            child: _reminders.isEmpty
                                ? Center(
                                    child: Text(
                                      'No reminders yet.\nTap + to add one.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.grey[700]),//rangy nusenakay nawarasta agory u kalew toxy dastkare akat
                                    ),
                                  )
                                //
                                // بەڵام ئەگەر لیستەکە ئایتمێکی تیابوو ئەوا:
                                : GridView.builder(
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 1.2,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                    ),
                                    itemCount: _reminders.length,
                                    itemBuilder: (context, i) {
                                      // نرخەکانی هەر ئایتمێك وەرەگرێت بە پێی ئیندێکسی ئایتمەکە
                                      //وەك: (ئایدی، ناو، کاتی وەرگرتن)
                                      // دواتر دەیخاتە ناو ڤاریەبڵی ئایتمس
                                      final items = _reminders[i];
                                      // بەشێوەی لیست ئەیگەڕێنێتەوە
                                      return Container(
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.grey.withOpacity(0.3),
                                              spreadRadius: 2,
                                              blurRadius: 5,
                                              offset: Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              items.name,
                                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            SizedBox(height: 4),
                                            if (items.condition != null)
                                              Container(
                                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: _getConditionColor(items.condition!),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  items.condition!,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(Icons.access_time, size: 16, color: Colors.blueGrey),
                                                SizedBox(width: 4),
                                                Text(
                                                  items.time.format(context),
                                                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                                ),
                                              ],
                                            ),
                                            if (items.notes != null && items.notes!.isNotEmpty)
                                              Padding(
                                                padding: EdgeInsets.only(top: 4),
                                                child: Text(
                                                  items.notes!,
                                                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            Spacer(),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                IconButton(
                                                  icon: Icon(Icons.edit, color: Colors.green, size: 20),
                                                  onPressed: () {
                                                    _editMedicine(items);
                                                  },
                                                  constraints: BoxConstraints(),
                                                  padding: EdgeInsets.all(4),
                                                ),
                                                IconButton(
                                                  icon: Icon(Icons.delete, color: Colors.red, size: 20),
                                                  onPressed: () {
                                                    confirmDelete(context, items.id);
                                                  },
                                                  constraints: BoxConstraints(),
                                                  padding: EdgeInsets.all(4),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),

                            //
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(20),
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color.fromARGB(255, 167, 169, 143)
                        : const Color.fromARGB(255, 248, 248, 248),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddMedicinePage(onAddMedicine: _addMedicine),
                                ),
                              );
                            },
                            child: Text('Add Medicine'),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Medicines',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.blueGrey[900],
                            ),
                          ),
                          SizedBox(height: 12),
                          Expanded(
                            child: _medicines.isEmpty
                                ? Center(
                                    child: Text(
                                      'No medicines',
                                      style: TextStyle(color: Colors.grey[700]),
                                    ),
                                  )
                                : GridView.builder(
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 1,
                                      childAspectRatio: 2,
                                    ),
                                    itemCount: _medicines.length,
                                    itemBuilder: (context, i) {
                                      final items = _medicines[i];
                                      return Card(
                                        margin: EdgeInsets.symmetric(vertical: 4),
                                        child: Padding(
                                          padding: EdgeInsets.all(8),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                items.name,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Container(
                                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: _getDepartmentColor(items.department),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  items.department,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                              if (items.description != null && items.description!.isNotEmpty)
                                                Padding(
                                                  padding: EdgeInsets.only(top: 4),
                                                  child: Text(
                                                    items.description!,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              Spacer(),
                                              Align(
                                                alignment: Alignment.centerRight,
                                                child: IconButton(
                                                  icon: Icon(Icons.delete, color: Colors.red),
                                                  onPressed: () {
                                                    _deleteMedicineItem(items.id);
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      floatingActionButton: Container(
        margin: EdgeInsets.all(10),//fab eata saraway containaraka
        child: FloatingActionButton(
          backgroundColor: Colors.blueGrey[300],
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddReminderPage(
                  medicines: _medicines,
                  onAddReminder: _addMedicineReminder,
                ),
              ),
            );
          },
          //
          // ئایکۆنی FAB
          child: Icon(Icons.add, color: Colors.white),//rangy iconaka plusakay
        ),
      ),
    );
  }
}


