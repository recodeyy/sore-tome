/// Placeholder data classes — neutralized for backend integration.
/// Every property referenced by the UI is present here, initialized to
/// empty / zero / blank values.  No fake business data is included.
/// TODO: Replace each field with real API data when backend is ready.

class MockDashboardData {
  static const String societyName = '';
  static const String societyType = '';
  static const String adminName = '';
  static const String dateLabel = '';

  // Today's Overview
  static const int pendingApprovals = 0;
  static const int openComplaints = 0;
  static const String todaysCollection = '₹ 0';
  static const String maintenanceDue = '₹ 0';
  static const int visitorsToday = 0;
  static const int staffOnDuty = 0;

  // Revenue Overview
  static const String totalCollection = '₹ 0';
  static const String totalCollectionTrend = '0%';
  static const String collectedAmount = '₹ 0';
  static const String pendingAmount = '₹ 0';
  static const String overdueAmount = '₹ 0';
  static const String monthLabel = '';

  // Collection Trend
  static const List<double> collectionTrend = [];
  static const List<String> collectionWeeks = [];

  // Category wise collection
  static const String categoryTotal = '₹ 0';
  static const List<Map<String, dynamic>> categoryBreakdown = [];

  // Revenue chart data
  static const List<double> revenueLineData = [];
  static const List<String> revenueLabels = [];

  // Finance
  static const String pendingDues = '₹ 0';
  static const String pendingDuesTrend = '0%';
  static const String thisMonthRevenue = '₹ 0';
  static const String totalExpenses = '₹ 0';
  static const String totalExpensesTrend = '0%';
  static const String maintenanceDueAmount = '₹ 0';
  static const int maintenanceDueFlats = 0;

  // Insights
  static const double collectionEfficiency = 0.0;
  static const double complaintResolution = 0.0;
  static const double occupancyRate = 0.0;

  // Complaints
  static const int totalComplaints = 0;
  static const int openComplaintsCount = 0;
  static const int inProgressComplaints = 0;
  static const int resolvedComplaints = 0;
  static const int closedComplaints = 0;

  // Visitors
  static const int checkedIn = 0;
  static const String checkedInTrend = '0%';
  static const int checkedOut = 0;
  static const String checkedOutTrend = '0%';

  // Events
  static const List<Map<String, String>> upcomingEvents = [];

  // Activity
  static const List<Map<String, dynamic>> recentActivity = [];

  // Notice Highlights
  static const List<Map<String, dynamic>> noticeHighlights = [];

  // Quick Stats
  static const int totalMembers = 0;
  static const int totalFlats = 0;
  static const int totalStaff = 0;
  static const int totalVehicles = 0;
}

class MockSocietyData {
  static const String name = '';
  static const String code = '';
  static const String type = '';
  static const String registrationNumber = '';
  static const String description = '';
  static const String establishedOn = '';
  static const String logoUpdateDate = '';
  static const int totalMembers = 0;
  static const int totalFlats = 0;
  static const int totalWings = 0;
  static const int totalBlocks = 0;
  static const int ownerCount = 0;
  static const int tenantCount = 0;
  static const int vacantCount = 0;
  static const int flatsTotalCount = 0;
  static const List<Map<String, String>> societyInfo = [];
  static const Map<String, dynamic> wingsBlocks = {};
  static const List<Map<String, dynamic>> wings = [];
  static const List<Map<String, dynamic>> blocks = [];
  static const List<Map<String, dynamic>> flatUnits = [];
  static const List<Map<String, dynamic>> flats = [];
}

class MockParkingData {
  static const int totalSlots = 0;
  static const int allocatedSlots = 0;
  static const int availableSlots = 0;
  static const int reservedSlots = 0;
  static const int residentVehicles = 0;
  static const int visitorVehicles = 0;
  static const int pendingRequests = 0;
  static const int violationCases = 0;
  static const List<Map<String, dynamic>> slots = [];
  static const List<Map<String, dynamic>> parkingSlots = [];
  static const List<Map<String, dynamic>> allocations = [];
  static const List<Map<String, dynamic>> recentActivity = [];
}

class MockAssetsData {
  static const int totalAssets = 0;
  static const int operational = 0;
  static const int underMaintenance = 0;
  static const int outOfService = 0;
  static const int categoriesCount = 0;
  static const int maintenanceDue = 0;
  static const List<Map<String, dynamic>> assets = [];
  static const List<Map<String, dynamic>> categories = [];
  static const List<Map<String, dynamic>> maintenanceLogs = [];
  static const List<Map<String, dynamic>> recentLogs = [];
  static const List<Map<String, dynamic>> upcomingMaintenance = [];
  static const List<Map<String, dynamic>> recentActivity = [];
  static const Map<String, dynamic> liftDetail = {};
}

class MockFinanceData {
  static const String totalRevenue = '₹ 0';
  static const String totalRevenueTrend = '0%';
  static const String totalExpenses = '₹ 0';
  static const String totalExpensesTrend = '0%';
  static const String totalCollection = '₹ 0';
  static const String totalCollectionTrend = '0%';
  static const String maintenanceDue = '₹ 0';
  static const int maintenanceDueFlats = 0;
  static const String pendingDues = '₹ 0';
  static const String pendingDuesTrend = '0%';
  static const String thisMonthRevenue = '₹ 0';
  static const List<Map<String, dynamic>> recentTransactions = [];
  static const List<Map<String, dynamic>> topCollections = [];
  static const List<Map<String, dynamic>> incomeVsExpenseData = [];
  static const Map<String, dynamic> ledgerSummary = {
    'totalIncome': '₹ 0',
    'totalExpenses': '₹ 0',
    'netBalance': '₹ 0',
    'transactions': 0,
  };
  static const List<String> billTypes = [];
  static const List<String> wings = [];
  static const List<String> blocks = [];
  static const Map<String, dynamic> sampleBill = {};
  static const List<Map<String, dynamic>> paymentHistory = [];
}

class MockCommunicationData {
  static const List<Map<String, dynamic>> notices = [];
  static const List<Map<String, dynamic>> categories = [];
}

class MockStaffData {
  static const int totalStaff = 0;
  static const int activeStaff = 0;
  static const int presentToday = 0;
  static const int presentPercent = 0;
  static const int onLeave = 0;
  static const int onLeavePercent = 0;
  static const List<Map<String, dynamic>> staffList = [];
  static const List<Map<String, dynamic>> recentActivity = [];
}

class MockAmenitiesData {
  static const int totalAmenities = 0;
  static const int activeBookings = 0;
  static const int todaysBookings = 0;
  static const int pendingApproval = 0;
  static const String monthRevenue = '₹ 0';
  static const List<Map<String, dynamic>> amenities = [];
  static const List<Map<String, dynamic>> upcomingBookings = [];
}

class MockComplaintsData {
  static const int totalCount = 0;
  static const int totalComplaints = 0;
  static const int openCount = 0;
  static const int openPercent = 0;
  static const int inProgressCount = 0;
  static const int inProgressPercent = 0;
  static const int resolvedCount = 0;
  static const int resolvedPercent = 0;
  static const int overdueCount = 0;
  static const int overduePercent = 0;
  static const int dueTodayCount = 0;
  static const int dueTodayPercent = 0;
  static const List<Map<String, dynamic>> recentComplaints = [];
  static const Map<String, dynamic> sampleDetail = {};
}

class MockReportsData {
  static const int reportsThisMonth = 0;
  static const int autoScheduled = 0;
  static const int totalReportsGenerated = 0;
  static const int scheduledReports = 0;
  static const int totalDownloads = 0;
  static const String totalIncome = '₹ 0';
  static const String totalExpense = '₹ 0';
  static const String netSurplus = '₹ 0';
  static const int transactionCount = 0;
  static const List<Map<String, dynamic>> categories = [
    {'title': 'Financial Reports', 'count': 0, 'icon': 0xe041, 'color': 0xFF059669},
    {'title': 'Visitor Reports', 'count': 0, 'icon': 0xe491, 'color': 0xFF2563EB},
    {'title': 'Staff Reports', 'count': 0, 'icon': 0xe0af, 'color': 0xFF7C3AED},
    {'title': 'Complaint Reports', 'count': 0, 'icon': 0xe11e, 'color': 0xFFEF4444},
  ];
  static const List<Map<String, dynamic>> financialCategories = [];
  static const List<Map<String, dynamic>> recentReports = [];
}
