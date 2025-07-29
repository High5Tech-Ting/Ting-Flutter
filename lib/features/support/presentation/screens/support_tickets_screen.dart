import 'package:flutter/material.dart';
import 'package:ting/core/models/support_ticket_model.dart';
import 'package:ting/core/services/support_ticket_service.dart';
import 'package:ting/core/services/admin_service.dart';
import 'package:ting/features/support/presentation/screens/create_ticket_screen.dart';
import 'package:ting/features/support/presentation/screens/ticket_detail_screen.dart';
import 'package:ting/features/support/presentation/widgets/ticket_card.dart';
import 'package:ting/shared/theme.dart';

class SupportTicketsScreen extends StatefulWidget {
  const SupportTicketsScreen({super.key});

  @override
  State<SupportTicketsScreen> createState() => _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends State<SupportTicketsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Support Tickets',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Resolved'),
            Tab(text: 'Closed'),
          ],
          dividerColor: Colors.transparent,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TicketList(status: TicketStatus.pending),
          _TicketList(status: TicketStatus.resolved),
          _TicketList(status: TicketStatus.closed),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateTicketScreen()),
          );
        },
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _TicketList extends StatelessWidget {
  final TicketStatus status;

  const _TicketList({required this.status});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SupportTicket>>(
      stream: AdminService.isCurrentUserAdmin()
          ? SupportTicketService.getAllTicketsByStatus(status)
          : SupportTicketService.getTicketsByStatus(status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final tickets = snapshot.data ?? [];

        if (tickets.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.support_agent_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No ${status.name} tickets',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your ${status.name} support tickets will appear here',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: tickets.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: TicketCard(
                ticket: tickets[index],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          TicketDetailScreen(ticketId: tickets[index].ticketId),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
