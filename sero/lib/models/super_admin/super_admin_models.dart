typedef JsonMap = Map<String, dynamic>;

String _stringValue(
  JsonMap json,
  List<String> keys, [
  String fallback = '',
]) {
  for (final key in keys) {
    final value = json[key];
    if (value != null) return value.toString();
  }
  return fallback;
}

int _intValue(JsonMap json, List<String> keys, [int fallback = 0]) {
  for (final key in keys) {
    final value = json[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
  }
  return fallback;
}

double _doubleValue(JsonMap json, List<String> keys, [double fallback = 0]) {
  for (final key in keys) {
    final value = json[key];
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
  }
  return fallback;
}

bool _boolValue(JsonMap json, List<String> keys, [bool fallback = false]) {
  for (final key in keys) {
    final value = json[key];
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
  }
  return fallback;
}

DateTime? _dateValue(JsonMap json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  }
  return null;
}

List<JsonMap> _jsonList(dynamic value) {
  if (value is List) {
    return value.whereType<Map>().map((item) => JsonMap.from(item)).toList();
  }
  return const [];
}

JsonMap _jsonMap(dynamic value) {
  if (value is Map) return JsonMap.from(value);
  return const {};
}

class SuperAdminMetric {
  final String key;
  final String label;
  final String value;
  final String trend;
  final bool trendUp;

  const SuperAdminMetric({
    required this.key,
    required this.label,
    required this.value,
    this.trend = '',
    this.trendUp = true,
  });

  factory SuperAdminMetric.fromJson(JsonMap json) {
    final trendDirection = _stringValue(
        json,
        [
          'trendDirection',
          'direction',
        ],
        'up');
    return SuperAdminMetric(
      key: _stringValue(json, ['key', 'id', 'metric']),
      label: _stringValue(json, ['label', 'title', 'name']),
      value: _stringValue(json, ['value', 'displayValue', 'count'], '0'),
      trend: _stringValue(json, ['trend', 'delta', 'change']),
      trendUp: trendDirection != 'down' && !trendDirection.startsWith('-'),
    );
  }
}

class SuperAdminTrendPoint {
  final String label;
  final double value;
  final DateTime? date;

  const SuperAdminTrendPoint({
    required this.label,
    required this.value,
    this.date,
  });

  factory SuperAdminTrendPoint.fromJson(JsonMap json) {
    return SuperAdminTrendPoint(
      label: _stringValue(json, ['label', 'period', 'date']),
      value: _doubleValue(json, ['value', 'amount', 'count']),
      date: _dateValue(json, ['date', 'periodStart']),
    );
  }
}

class SuperAdminFunnelStep {
  final String label;
  final int count;
  final double completionRate;

  const SuperAdminFunnelStep({
    required this.label,
    required this.count,
    required this.completionRate,
  });

  factory SuperAdminFunnelStep.fromJson(JsonMap json) {
    return SuperAdminFunnelStep(
      label: _stringValue(json, ['label', 'name', 'step']),
      count: _intValue(json, ['count', 'societies']),
      completionRate: _doubleValue(json, [
        'completionRate',
        'completion',
        'rate',
      ]),
    );
  }
}

class SuperAdminHealthSignal {
  final String label;
  final String status;
  final String detail;
  final String severity;

  const SuperAdminHealthSignal({
    required this.label,
    required this.status,
    this.detail = '',
    this.severity = 'info',
  });

  factory SuperAdminHealthSignal.fromJson(JsonMap json) {
    return SuperAdminHealthSignal(
      label: _stringValue(json, ['label', 'service', 'name']),
      status: _stringValue(json, ['status', 'state'], 'unknown'),
      detail: _stringValue(json, ['detail', 'message', 'description']),
      severity: _stringValue(json, ['severity', 'level'], 'info'),
    );
  }
}

class SuperAdminActivity {
  final String id;
  final String title;
  final String subtitle;
  final String actor;
  final String status;
  final DateTime? occurredAt;

  const SuperAdminActivity({
    required this.id,
    required this.title,
    this.subtitle = '',
    this.actor = '',
    this.status = '',
    this.occurredAt,
  });

  factory SuperAdminActivity.fromJson(JsonMap json) {
    return SuperAdminActivity(
      id: _stringValue(json, ['id', 'eventId', 'requestId']),
      title: _stringValue(json, ['title', 'action', 'event']),
      subtitle: _stringValue(json, ['subtitle', 'description', 'module']),
      actor: _stringValue(json, ['actor', 'actorName', 'createdBy']),
      status: _stringValue(json, ['status', 'result']),
      occurredAt: _dateValue(json, ['occurredAt', 'createdAt', 'timestamp']),
    );
  }
}

class SuperAdminRevenueSnapshot {
  final double mrr;
  final double arr;
  final double collectedThisMonth;
  final double outstanding;
  final double refunds;
  final int failedPayments;
  final double trialConversionRate;
  final Map<String, double> revenueByPlan;
  final List<SuperAdminTrendPoint> trend;
  final List<SuperAdminSociety> topSocieties;

  const SuperAdminRevenueSnapshot({
    this.mrr = 0,
    this.arr = 0,
    this.collectedThisMonth = 0,
    this.outstanding = 0,
    this.refunds = 0,
    this.failedPayments = 0,
    this.trialConversionRate = 0,
    this.revenueByPlan = const {},
    this.trend = const [],
    this.topSocieties = const [],
  });

  factory SuperAdminRevenueSnapshot.fromJson(JsonMap json) {
    final byPlan = <String, double>{};
    _jsonMap(json['revenueByPlan'] ?? json['byPlan']).forEach((key, value) {
      if (value is num) byPlan[key] = value.toDouble();
    });

    return SuperAdminRevenueSnapshot(
      mrr: _doubleValue(json, ['mrr', 'monthlyRecurringRevenue']),
      arr: _doubleValue(json, ['arr', 'annualRecurringRevenue']),
      collectedThisMonth: _doubleValue(json, [
        'collectedThisMonth',
        'collections',
        'collectionThisMonth',
      ]),
      outstanding: _doubleValue(json, ['outstanding', 'outstandingAmount']),
      refunds: _doubleValue(json, ['refunds', 'refundAmount']),
      failedPayments: _intValue(json, ['failedPayments', 'failedPaymentCount']),
      trialConversionRate: _doubleValue(json, [
        'trialConversionRate',
        'trialConversion',
      ]),
      revenueByPlan: byPlan,
      trend: _jsonList(json['trend'] ?? json['revenueTrend'])
          .map(SuperAdminTrendPoint.fromJson)
          .toList(),
      topSocieties: _jsonList(json['topSocieties'] ?? json['topRevenue'])
          .map(SuperAdminSociety.fromJson)
          .toList(),
    );
  }
}

class SuperAdminSupportSummary {
  final int openTickets;
  final int breachedSla;
  final int dueSoon;
  final String averageFirstResponse;
  final double csat;

  const SuperAdminSupportSummary({
    this.openTickets = 0,
    this.breachedSla = 0,
    this.dueSoon = 0,
    this.averageFirstResponse = '0h',
    this.csat = 0,
  });

  factory SuperAdminSupportSummary.fromJson(JsonMap json) {
    return SuperAdminSupportSummary(
      openTickets: _intValue(json, ['openTickets', 'open']),
      breachedSla: _intValue(json, ['breachedSla', 'breached']),
      dueSoon: _intValue(json, ['dueSoon', 'atRisk']),
      averageFirstResponse: _stringValue(
          json,
          [
            'averageFirstResponse',
            'avgFirstResponse',
          ],
          '0h'),
      csat: _doubleValue(json, ['csat', 'csatScore']),
    );
  }
}

class SuperAdminDashboard {
  final String adminName;
  final int unreadNotifications;
  final List<SuperAdminMetric> metrics;
  final SuperAdminRevenueSnapshot revenue;
  final List<SuperAdminFunnelStep> onboardingFunnel;
  final List<SuperAdminTrendPoint> activityTrend;
  final List<SuperAdminSociety> atRiskSocieties;
  final SuperAdminSupportSummary support;
  final List<SuperAdminHealthSignal> health;
  final List<SuperAdminActivity> recentActivity;
  final double aiSpend;
  final int failedJobs;

  const SuperAdminDashboard({
    this.adminName = 'Super Admin',
    this.unreadNotifications = 0,
    this.metrics = const [],
    this.revenue = const SuperAdminRevenueSnapshot(),
    this.onboardingFunnel = const [],
    this.activityTrend = const [],
    this.atRiskSocieties = const [],
    this.support = const SuperAdminSupportSummary(),
    this.health = const [],
    this.recentActivity = const [],
    this.aiSpend = 0,
    this.failedJobs = 0,
  });

  factory SuperAdminDashboard.fromJson(JsonMap json) {
    return SuperAdminDashboard(
      adminName: _stringValue(json, ['adminName', 'name'], 'Super Admin'),
      unreadNotifications: _intValue(json, [
        'unreadNotifications',
        'notifications',
      ]),
      metrics: _jsonList(json['metrics'] ?? json['stats'])
          .map(SuperAdminMetric.fromJson)
          .toList(),
      revenue: SuperAdminRevenueSnapshot.fromJson(
        _jsonMap(json['revenue'] ?? json['revenueSnapshot']),
      ),
      onboardingFunnel: _jsonList(json['onboardingFunnel'] ?? json['funnel'])
          .map(SuperAdminFunnelStep.fromJson)
          .toList(),
      activityTrend: _jsonList(json['activityTrend'] ?? json['dauMauTrend'])
          .map(SuperAdminTrendPoint.fromJson)
          .toList(),
      atRiskSocieties: _jsonList(json['atRiskSocieties'])
          .map(SuperAdminSociety.fromJson)
          .toList(),
      support: SuperAdminSupportSummary.fromJson(
        _jsonMap(json['support'] ?? json['supportSummary']),
      ),
      health: _jsonList(json['health'] ?? json['platformHealth'])
          .map(SuperAdminHealthSignal.fromJson)
          .toList(),
      recentActivity: _jsonList(json['recentActivity'] ?? json['activity'])
          .map(SuperAdminActivity.fromJson)
          .toList(),
      aiSpend: _doubleValue(_jsonMap(json['aiUsage'] ?? json['ai']), [
        'spend',
        'cost',
      ]),
      failedJobs: _intValue(json, ['failedJobs', 'criticalAlerts']),
    );
  }
}

class SuperAdminSociety {
  final String id;
  final String name;
  final String city;
  final String state;
  final String plan;
  final String status;
  final int members;
  final int mau;
  final double setupCompletion;
  final DateTime? renewalDate;
  final String health;
  final String logoUrl;
  final double monthlyRevenue;
  final bool atRisk;
  final List<JsonMap> features;

  const SuperAdminSociety({
    required this.id,
    required this.name,
    this.city = '',
    this.state = '',
    this.plan = '',
    this.status = 'unknown',
    this.members = 0,
    this.mau = 0,
    this.setupCompletion = 0,
    this.renewalDate,
    this.health = 'unknown',
    this.logoUrl = '',
    this.monthlyRevenue = 0,
    this.atRisk = false,
    this.features = const [],
  });

  factory SuperAdminSociety.fromJson(JsonMap json) {
    return SuperAdminSociety(
      id: _stringValue(json, ['id', 'societyId', 'uid']),
      name: _stringValue(json, ['name', 'societyName'], 'Unnamed society'),
      city: _stringValue(json, ['city']),
      state: _stringValue(json, ['state']),
      plan: _stringValue(json, ['plan', 'planName']),
      status: _stringValue(json, ['status'], 'unknown'),
      members: _intValue(json, ['members', 'memberCount', 'users']),
      mau: _intValue(json, ['mau', 'monthlyActiveUsers']),
      setupCompletion: _doubleValue(json, [
        'setupCompletion',
        'setupCompletionRate',
        'completion',
      ]),
      renewalDate: _dateValue(json, ['renewalDate', 'subscriptionRenewal']),
      health: _stringValue(json, ['health', 'healthStatus'], 'unknown'),
      logoUrl: _stringValue(json, ['logoUrl', 'logo']),
      monthlyRevenue: _doubleValue(json, [
        'monthlyRevenue',
        'mrr',
        'revenue',
      ]),
      atRisk: _boolValue(json, ['atRisk', 'isAtRisk']),
      features: _jsonList(json['features'] ?? json['featureOverrides']),
    );
  }
}

class SuperAdminSocietiesPage {
  final List<SuperAdminSociety> items;
  final String? nextCursor;
  final int total;

  const SuperAdminSocietiesPage({
    required this.items,
    this.nextCursor,
    this.total = 0,
  });

  bool get hasMore => nextCursor != null && nextCursor!.isNotEmpty;

  factory SuperAdminSocietiesPage.fromJson(JsonMap json) {
    final list = json['societies'] ?? json['items'] ?? json['data'];
    return SuperAdminSocietiesPage(
      items: _jsonList(list).map(SuperAdminSociety.fromJson).toList(),
      nextCursor: _stringValue(json, ['nextCursor', 'cursor']).isEmpty
          ? null
          : _stringValue(json, ['nextCursor', 'cursor']),
      total: _intValue(json, ['total', 'count']),
    );
  }
}

class SuperAdminSocietyFilters {
  final String query;
  final String status;
  final String sort;
  final int limit;

  const SuperAdminSocietyFilters({
    this.query = '',
    this.status = 'all',
    this.sort = 'recently_added',
    this.limit = 20,
  });

  SuperAdminSocietyFilters copyWith({
    String? query,
    String? status,
    String? sort,
    int? limit,
  }) {
    return SuperAdminSocietyFilters(
      query: query ?? this.query,
      status: status ?? this.status,
      sort: sort ?? this.sort,
      limit: limit ?? this.limit,
    );
  }

  Map<String, String> toQuery({String? cursor}) {
    return {
      if (query.trim().isNotEmpty) 'q': query.trim(),
      if (status != 'all') 'status': status,
      'sort': sort,
      'limit': limit.toString(),
      if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
    };
  }
}

class SuperAdminSupportTicket {
  final String id;
  final String subject;
  final String societyName;
  final String reporter;
  final String priority;
  final String category;
  final String status;
  final String assignee;
  final DateTime? slaDueAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final double csat;

  const SuperAdminSupportTicket({
    required this.id,
    required this.subject,
    this.societyName = '',
    this.reporter = '',
    this.priority = 'normal',
    this.category = '',
    this.status = 'open',
    this.assignee = '',
    this.slaDueAt,
    this.createdAt,
    this.updatedAt,
    this.csat = 0,
  });

  factory SuperAdminSupportTicket.fromJson(JsonMap json) {
    return SuperAdminSupportTicket(
      id: _stringValue(json, ['id', 'ticketId']),
      subject: _stringValue(json, ['subject', 'title'], 'Untitled ticket'),
      societyName: _stringValue(json, ['societyName', 'society']),
      reporter: _stringValue(json, ['reporter', 'reporterName', 'createdBy']),
      priority: _stringValue(json, ['priority'], 'normal'),
      category: _stringValue(json, ['category', 'type']),
      status: _stringValue(json, ['status'], 'open'),
      assignee: _stringValue(json, ['assignee', 'assigneeName']),
      slaDueAt: _dateValue(json, ['slaDueAt', 'dueAt']),
      createdAt: _dateValue(json, ['createdAt']),
      updatedAt: _dateValue(json, ['updatedAt']),
      csat: _doubleValue(json, ['csat', 'csatScore']),
    );
  }
}

class SuperAdminSupportDashboard {
  final SuperAdminSupportSummary summary;
  final List<SuperAdminSupportTicket> tickets;

  const SuperAdminSupportDashboard({
    this.summary = const SuperAdminSupportSummary(),
    this.tickets = const [],
  });

  factory SuperAdminSupportDashboard.fromJson(JsonMap json) {
    return SuperAdminSupportDashboard(
      summary: SuperAdminSupportSummary.fromJson(
        _jsonMap(json['summary'] ?? json['sla'] ?? json),
      ),
      tickets: _jsonList(json['tickets'] ?? json['items'] ?? json['data'])
          .map(SuperAdminSupportTicket.fromJson)
          .toList(),
    );
  }
}

class SuperAdminModuleLink {
  final String title;
  final String subtitle;
  final String route;
  final String group;
  final String iconKey;
  final bool sensitive;

  const SuperAdminModuleLink({
    required this.title,
    required this.subtitle,
    required this.route,
    required this.group,
    required this.iconKey,
    this.sensitive = false,
  });
}
