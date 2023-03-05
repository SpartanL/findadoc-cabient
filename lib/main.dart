import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(
    title: 'Recherche de rendez-vous',
    initialRoute: '/',
    routes: {
      '/': (context) => const MyApp(),
      '/addDoctor': (context) => const AddDoctorPage(),
    },
  ));
}


class MyApp extends StatefulWidget {
  const MyApp({Key? key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late List<String> _doctorNames = <String>[];
  String? _selectedDoctorName;
  List<Map<String, dynamic>> _appointments = [];

  @override
  void initState() {
    super.initState();
    searchDoctors();
  }

  void searchDoctors() {
    FirebaseFirestore.instance
        .collection('doctors')
        .get()
        .then((querySnapshot) {
      setState(() {
        _doctorNames = List<String>.from(querySnapshot.docs
            .map((documentSnapshot) => documentSnapshot.get('nom')));
      });
    });
  }


  void searchAppointments(String doctorName) {
    FirebaseFirestore.instance
        .collection('appointments')
        .where('doctor.nom', isEqualTo: doctorName)
        .get()
        .then((querySnapshot) {
      setState(() {
        _appointments = querySnapshot.docs
            .map((documentSnapshot) => documentSnapshot.data())
            .toList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recherche de rendez-vous',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Recherche de rendez-vous'),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.pushNamed(context, '/addDoctor');
                },
            ),

          ],
        ),

        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              DropdownButton<String>(
                value: _selectedDoctorName,
                hint: const Text('Sélectionnez un médecin'),
                items: _doctorNames
                    .map((doctorName) => DropdownMenuItem<String>(
                  value: doctorName,
                  child: Text(doctorName),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDoctorName = value!;
                  });
                },
              ),
              ElevatedButton(
                child: const Text('Rechercher'),
                onPressed: () {
                  if (_selectedDoctorName != null) {
                    searchAppointments(_selectedDoctorName!);
                  }
                },
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _appointments.length,
                  itemBuilder: (BuildContext context, int index) {
                    final appointment = _appointments[index];
                    return ListTile(
                      title: Text(appointment['nom']+ " " +appointment['prenom']),
                      subtitle: Text(DateFormat('HH:mm dd/MM').format(appointment['date'].toDate())),
                      trailing: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("Sexe: ${appointment['sexe']}"),
                          Text("Age: ${appointment['age']}"),
                        ],
                      ),
                    );

                  },
                ),
              )

            ],
          ),
        ),
      ),
    );
  }
}


class AddDoctorPage extends StatefulWidget {
  const AddDoctorPage({Key? key}) : super(key: key);

  @override
  AddDoctorPageState createState() => AddDoctorPageState();
}

class AddDoctorPageState extends State<AddDoctorPage> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedDomain;
  String? _doctorName;
  String? _doctorLastName;

  final List<String> _domains = [    'Généraliste',    'Ophtalmologue',    'Dentiste',    'Gynécologue',    'Pédiatre',    'Dermatologue',    'Chirurgien'  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un médecin'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedDomain,
                decoration: const InputDecoration(
                  labelText: 'Domaine',
                ),
                items: _domains.map((domain) {
                  return DropdownMenuItem<String>(
                    value: domain,
                    child: Text(domain),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDomain = value!;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Veuillez sélectionner un domaine';
                  }
                  return null;
                },
              ),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Nom',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un nom';
                  }
                  return null;
                },
                onSaved: (value) {
                  setState(() {
                    _doctorName = value!;
                  });
                },
              ),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Prénom',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un prénom';
                  }
                  return null;
                },
                onSaved: (value) {
                  setState(() {
                    _doctorLastName = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                child: const Text('Ajouter'),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();

                    FirebaseFirestore.instance.collection('doctors').add({
                      'nom': _doctorName,
                      'prenom': _doctorLastName,
                      'domaine': _selectedDomain,
                    }).then((value) {
                      Navigator.of(context).pop();
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}