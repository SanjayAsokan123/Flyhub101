import 'package:flutter/material.dart';

class JobApplyStatusPage extends StatefulWidget {
  const JobApplyStatusPage({super.key});

  @override
  State<JobApplyStatusPage> createState() => _JobApplyStatusPageState();
}

class _JobApplyStatusPageState extends State<JobApplyStatusPage> {
  // Sample data
  List<Map<String, dynamic>> applications = [
    {
      'jobTitle': 'Flutter Developer',
      'company': 'Tech Solutions',
      'status': 'Pending', // Pending, Approved, Rejected
      'date': '2025-01-10'
    },
    {
      'jobTitle': 'Backend Engineer',
      'company': 'SoftCorp',
      'status': 'Approved',
      'date': '2025-01-07'
    },
    {
      'jobTitle': 'UI/UX Designer',
      'company': 'Creatify Labs',
      'status': 'Rejected',
      'date': '2025-01-05'
    },
  ];

  Color getStatusColor(String status) {
    switch (status) {
      case 'Approved':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.orange; // Pending
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: const Text('Job Apply Status', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E0E5C),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: applications.length,
        itemBuilder: (context, index) {
          final item = applications[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['jobTitle'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item['company'],
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.circle, size: 12, color: getStatusColor(item['status'])),
                        const SizedBox(width: 6),
                        Text(
                          item['status'],
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: getStatusColor(item['status']),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      item['date'],
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    )
                  ],
                ),
                const SizedBox(height: 16),

                // Approve & Reject Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            applications[index]['status'] = 'Approved';
                          });
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: const Text('Approve'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            applications[index]['status'] = 'Rejected';
                          });
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Reject'),
                      ),
                    ),
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }
}