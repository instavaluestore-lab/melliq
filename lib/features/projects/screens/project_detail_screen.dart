import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../company/models/company_context.dart';
import '../models/project.dart';
import '../models/project_activity_log.dart';
import '../models/project_file.dart';
import '../models/material_item.dart';
import '../models/project_stage_cost.dart';
import '../models/project_stage_cost_item.dart';
import '../models/project_task.dart';
import '../models/project_task_assignee.dart';
import '../services/project_service.dart';
import '../services/project_activity_log_service.dart';
import '../services/project_file_service.dart';
import '../services/material_service.dart';
import '../services/project_stage_cost_service.dart';
import '../services/project_stage_cost_item_service.dart';
import '../services/project_task_service.dart';
import '../widgets/project_tasks_card.dart';
import '../widgets/project_files_card.dart';
import '../widgets/project_activity_card.dart';
import '../widgets/project_materials_card.dart';
import '../widgets/project_notes_card.dart';
import '../models/project_note.dart';
import '../services/project_note_service.dart';

class ProjectDetailScreen extends StatefulWidget {
  const ProjectDetailScreen({
    super.key,
    required this.companyContext,
    required this.project,
  });

  final CompanyContext companyContext;
  final Project project;

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  late final ProjectService projectService;
  late final ProjectFileService projectFileService;
  late final MaterialService materialService;
  late final ProjectStageCostService stageCostService;
  late final ProjectStageCostItemService stageCostItemService;
  late final ProjectTaskService projectTaskService;
  late final ProjectNoteService projectNoteService;
  late final ProjectActivityLogService projectActivityLogService;

  final contractAmountController = TextEditingController();

  bool isLoading = true;
  bool isSaving = false;
  String? errorMessage;

  late Project project;
  String selectedStatus = 'contract';
  List<ProjectStageCost> stageCosts = [];
  List<ProjectStageCostItem> stageCostItems = [];
  List<ProjectTask> projectTasks = [];
  List<ProjectFile> projectFiles = [];
  List<MaterialItem> projectMaterials = [];
  List<ProjectNote> projectNotes = [];
  List<ProjectActivityLog> projectActivityLogs = [];
  List<ProjectTaskAssignee> projectTaskAssignees = [];

  final Map<String, TextEditingController> itemDescriptionControllers = {};
  final Map<String, TextEditingController> itemActualCostControllers = {};

  final Map<String, TextEditingController> descriptionControllers = {};
  final Map<String, TextEditingController> estimatedControllers = {};
  final Map<String, TextEditingController> actualControllers = {};
  final Map<String, TextEditingController> notesControllers = {};
  final Map<String, TextEditingController> peopleControllers = {};
  final Map<String, TextEditingController> hoursControllers = {};
  final Map<String, TextEditingController> hourlyRateControllers = {};
  final Map<String, TextEditingController> flatFeeControllers = {};
  final Map<String, TextEditingController> concreteBagCountControllers = {};
  final Map<String, TextEditingController> concreteBagCostControllers = {};
  final Map<String, TextEditingController> rebarStickCountControllers = {};
  final Map<String, TextEditingController> rebarStickCostControllers = {};

  final Map<String, TextEditingController> anchorBoltCountControllers = {};
  final Map<String, TextEditingController> anchorBoltCostControllers = {};

  final Map<String, TextEditingController> fabricYardsControllers = {};
  final Map<String, TextEditingController> fabricCostPerYardControllers = {};
  final Map<String, TextEditingController> hardwareCountControllers = {};
  final Map<String, TextEditingController> hardwareCostEachControllers = {};
  final Map<String, TextEditingController> cableFeetControllers = {};
  final Map<String, TextEditingController> cableCostPerFootControllers = {};

  final Map<String, bool> completedValues = {};
  final Map<String, bool> useFlatFeeValues = {};
  final Map<String, String> concreteUnitTypeValues = {};
  final Map<String, String?> fabricTypeValues = {};

  @override
  void initState() {
    super.initState();

    project = widget.project;
    selectedStatus = project.status;
    contractAmountController.text = _formatMoneyInput(project.contractAmount);

    projectService = ProjectService(Supabase.instance.client);
    projectFileService = ProjectFileService(Supabase.instance.client);
    materialService = MaterialService(Supabase.instance.client);
    stageCostService = ProjectStageCostService(Supabase.instance.client);
    stageCostItemService = ProjectStageCostItemService(
      Supabase.instance.client,
    );
    projectTaskService = ProjectTaskService(Supabase.instance.client);
    projectNoteService = ProjectNoteService(Supabase.instance.client);
    projectActivityLogService = ProjectActivityLogService(
      Supabase.instance.client,
    );

    loadProjectDetail();
  }

  @override
  void dispose() {
    contractAmountController.dispose();

    for (final controller in [
      ...descriptionControllers.values,
      ...estimatedControllers.values,
      ...actualControllers.values,
      ...notesControllers.values,
      ...peopleControllers.values,
      ...hoursControllers.values,
      ...hourlyRateControllers.values,
      ...flatFeeControllers.values,
      ...concreteBagCountControllers.values,
      ...concreteBagCostControllers.values,
      ...rebarStickCountControllers.values,
      ...rebarStickCostControllers.values,
    ]) {
      controller.dispose();
    }

    super.dispose();
  }

  Future<void> loadProjectDetail() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final freshProject = await projectService.getProjectById(project.id);

      final freshStageCosts = await stageCostService.getStageCostsForProject(
        companyId: widget.companyContext.companyId,
        projectId: project.id,
      );

      final freshStageCostItems = await stageCostItemService.getItemsForProject(
        companyId: widget.companyContext.companyId,
        projectId: project.id,
      );

      final freshProjectTasks = await projectTaskService.getTasksForProject(
        companyId: widget.companyContext.companyId,
        projectId: project.id,
      );

      final freshProjectFiles = await projectFileService.getFilesForProject(
        companyId: widget.companyContext.companyId,
        projectId: project.id,
      );

      final freshProjectMaterials = await materialService
          .getMaterialsForProject(
            companyId: widget.companyContext.companyId,
            projectId: project.id,
          );

      final freshProjectActivityLogs = await projectActivityLogService
          .getProjectActivityLogs(projectId: project.id);

      _syncControllers(freshProject, freshStageCosts, freshStageCostItems);

      if (!mounted) return;

      setState(() {
        project = freshProject;
        selectedStatus = freshProject.status;
        stageCosts = freshStageCosts;
        stageCostItems = freshStageCostItems;
        projectTasks = freshProjectTasks;
        projectFiles = freshProjectFiles;
        projectMaterials = freshProjectMaterials;
        projectActivityLogs = freshProjectActivityLogs;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString();
        isLoading = false;
      });
    }
  }

  void _syncControllers(
    Project freshProject,
    List<ProjectStageCost> freshStageCosts,
    List<ProjectStageCostItem> freshStageCostItems,
  ) {
    contractAmountController.text = _formatMoneyInput(
      freshProject.contractAmount,
    );

    for (final stageCost in freshStageCosts) {
      descriptionControllers.putIfAbsent(
        stageCost.id,
        () => TextEditingController(),
      );
      estimatedControllers.putIfAbsent(
        stageCost.id,
        () => TextEditingController(),
      );
      actualControllers.putIfAbsent(
        stageCost.id,
        () => TextEditingController(),
      );
      notesControllers.putIfAbsent(stageCost.id, () => TextEditingController());
      peopleControllers.putIfAbsent(
        stageCost.id,
        () => TextEditingController(),
      );
      hoursControllers.putIfAbsent(stageCost.id, () => TextEditingController());
      hourlyRateControllers.putIfAbsent(
        stageCost.id,
        () => TextEditingController(),
      );
      flatFeeControllers.putIfAbsent(
        stageCost.id,
        () => TextEditingController(),
      );
      concreteBagCountControllers.putIfAbsent(
        stageCost.id,
        () => TextEditingController(),
      );
      concreteBagCostControllers.putIfAbsent(
        stageCost.id,
        () => TextEditingController(),
      );
      rebarStickCountControllers.putIfAbsent(
        stageCost.id,
        () => TextEditingController(),
      );
      rebarStickCostControllers.putIfAbsent(
        stageCost.id,
        () => TextEditingController(),
      );

      descriptionControllers
              .putIfAbsent(stageCost.id, () => TextEditingController())
              .text =
          stageCost.description ?? stageCost.stageLabel;
      estimatedControllers
          .putIfAbsent(stageCost.id, () => TextEditingController())
          .text = _formatMoneyInput(
        stageCost.estimatedCost,
      );
      actualControllers
          .putIfAbsent(stageCost.id, () => TextEditingController())
          .text = _formatMoneyInput(
        stageCost.actualCost,
      );
      notesControllers
              .putIfAbsent(stageCost.id, () => TextEditingController())
              .text =
          stageCost.notes ?? '';

      peopleControllers
          .putIfAbsent(stageCost.id, () => TextEditingController())
          .text = stageCost.peopleCount == 0
          ? ''
          : stageCost.peopleCount.toString();
      hoursControllers
          .putIfAbsent(stageCost.id, () => TextEditingController())
          .text = _formatMoneyInput(
        stageCost.hoursEach,
      );
      hourlyRateControllers
          .putIfAbsent(stageCost.id, () => TextEditingController())
          .text = _formatMoneyInput(
        stageCost.costPerHour,
      );
      flatFeeControllers
          .putIfAbsent(stageCost.id, () => TextEditingController())
          .text = _formatMoneyInput(
        stageCost.flatFee,
      );

      concreteBagCountControllers
          .putIfAbsent(stageCost.id, () => TextEditingController())
          .text = stageCost.concreteBagCount == 0
          ? ''
          : stageCost.concreteBagCount.toString();
      concreteBagCostControllers
          .putIfAbsent(stageCost.id, () => TextEditingController())
          .text = _formatMoneyInput(
        stageCost.concreteBagCost,
      );
      rebarStickCountControllers
          .putIfAbsent(stageCost.id, () => TextEditingController())
          .text = stageCost.rebarStickCount == 0
          ? ''
          : stageCost.rebarStickCount.toString();
      rebarStickCostControllers
          .putIfAbsent(stageCost.id, () => TextEditingController())
          .text = _formatMoneyInput(
        stageCost.rebarStickCost,
      );

      completedValues[stageCost.id] = stageCost.isCompleted;
      useFlatFeeValues[stageCost.id] = stageCost.useFlatFee;
      concreteUnitTypeValues[stageCost.id] = stageCost.concreteUnitType;
      fabricTypeValues[stageCost.id] = stageCost.fabricType;
    }

    for (final item in freshStageCostItems) {
      itemDescriptionControllers.putIfAbsent(
        item.id,
        () => TextEditingController(),
      );
      itemActualCostControllers.putIfAbsent(
        item.id,
        () => TextEditingController(),
      );

      itemDescriptionControllers[item.id]!.text = item.description ?? '';
      itemActualCostControllers[item.id]!.text = _formatMoneyInput(
        item.actualCost,
      );
    }
  }

  Future<void> addMiscellaneousExpense() async {
    setState(() {
      isSaving = true;
      errorMessage = null;
    });

    try {
      await stageCostService.createMiscellaneousExpense(
        companyId: widget.companyContext.companyId,
        projectId: project.id,
        createdBy: widget.companyContext.userId,
        description: '',
      );

      await loadProjectDetail();

      if (!mounted) return;

      setState(() {
        isSaving = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString();
        isSaving = false;
      });
    }
  }

  Future<void> addStageCostItem(ProjectStageCost stageCost) async {
    setState(() {
      isSaving = true;
      errorMessage = null;
    });

    try {
      final newItem = await stageCostItemService.createAdditionalActualCostItem(
        companyId: widget.companyContext.companyId,
        projectId: project.id,
        stageCostId: stageCost.id,
        createdBy: widget.companyContext.userId,
      );

      itemDescriptionControllers[newItem.id] = TextEditingController();
      itemActualCostControllers[newItem.id] = TextEditingController();

      if (!mounted) return;

      setState(() {
        stageCostItems = [...stageCostItems, newItem];
        isSaving = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString();
        isSaving = false;
      });
    }
  }

  Future<void> deleteStageCostItem(ProjectStageCostItem item) async {
    setState(() {
      isSaving = true;
      errorMessage = null;
    });

    try {
      await stageCostItemService.deleteItem(item.id);

      itemDescriptionControllers.remove(item.id)?.dispose();
      itemActualCostControllers.remove(item.id)?.dispose();

      if (!mounted) return;

      setState(() {
        stageCostItems = stageCostItems
            .where((stageCostItem) => stageCostItem.id != item.id)
            .toList();
        isSaving = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString();
        isSaving = false;
      });
    }
  }

  Future<void> saveProjectDetail() async {
    setState(() {
      isSaving = true;
      errorMessage = null;
    });

    try {
      final savedContractAmount = _parseMoney(contractAmountController.text);

      double savedEstimatedTotal = 0;
      double savedActualTotal = 0;

      for (final item in stageCostItems) {
        await stageCostItemService.updateItem(
          itemId: item.id,
          description: itemDescriptionControllers[item.id]?.text ?? '',
          actualCost: _parseMoney(
            itemActualCostControllers[item.id]?.text ?? '0',
          ),
        );
      }

      for (final stageCost in stageCosts) {
        final calculatedEstimated = _calculateEstimatedCost(stageCost);

        final baseActualCost = stageCost.isMilestoneOnly
            ? 0.0
            : _parseMoney(actualControllers[stageCost.id]?.text ?? '0');

        final addedActualCost = stageCostItems
            .where((item) => item.stageCostId == stageCost.id)
            .fold<double>(
              0,
              (total, item) =>
                  total +
                  _parseMoney(itemActualCostControllers[item.id]?.text ?? '0'),
            );

        savedEstimatedTotal += calculatedEstimated;
        savedActualTotal += baseActualCost + addedActualCost;

        await stageCostService.updateStageCost(
          stageCostId: stageCost.id,
          description: descriptionControllers[stageCost.id]?.text ?? '',
          estimatedCost: calculatedEstimated,
          actualCost: baseActualCost,
          notes: notesControllers[stageCost.id]?.text ?? '',
          anchorBoltCount: _parseInt(
            anchorBoltCountControllers[stageCost.id]?.text ?? '0',
          ),
          anchorBoltCost: _parseMoney(
            anchorBoltCostControllers[stageCost.id]?.text ?? '0',
          ),
          fabricType: fabricTypeValues[stageCost.id],
          fabricYards: _parseMoney(
            fabricYardsControllers[stageCost.id]?.text ?? '0',
          ),
          fabricCostPerYard: _parseMoney(
            fabricCostPerYardControllers[stageCost.id]?.text ?? '0',
          ),
          hardwareCount: _parseInt(
            hardwareCountControllers[stageCost.id]?.text ?? '0',
          ),
          hardwareCostEach: _parseMoney(
            hardwareCostEachControllers[stageCost.id]?.text ?? '0',
          ),
          cableFeet: _parseMoney(
            cableFeetControllers[stageCost.id]?.text ?? '0',
          ),
          cableCostPerFoot: _parseMoney(
            cableCostPerFootControllers[stageCost.id]?.text ?? '0',
          ),
          installationMiles: stageCost.installationMiles,
          installationCostPerMile: stageCost.installationCostPerMile,
          isCompleted: completedValues[stageCost.id] ?? false,
          peopleCount: _parseInt(peopleControllers[stageCost.id]?.text ?? '0'),
          hoursEach: _parseMoney(hoursControllers[stageCost.id]?.text ?? '0'),
          costPerHour: _parseMoney(
            hourlyRateControllers[stageCost.id]?.text ?? '0',
          ),
          flatFee: _parseMoney(flatFeeControllers[stageCost.id]?.text ?? '0'),
          useFlatFee: useFlatFeeValues[stageCost.id] ?? false,
          concreteBagCount: _parseInt(
            concreteBagCountControllers[stageCost.id]?.text ?? '0',
          ),
          concreteBagCost: _parseMoney(
            concreteBagCostControllers[stageCost.id]?.text ?? '0',
          ),
          concreteUnitType: concreteUnitTypeValues[stageCost.id] ?? 'bag',
          rebarStickCount: _parseInt(
            rebarStickCountControllers[stageCost.id]?.text ?? '0',
          ),
          rebarStickCost: _parseMoney(
            rebarStickCostControllers[stageCost.id]?.text ?? '0',
          ),
        );
      }

      final savedMaterialActualTotal = projectMaterials.fold<double>(
        0,
        (total, material) => total + material.totalCost,
      );

      await projectService.updateProjectStatus(
        projectId: project.id,
        status: selectedStatus,
      );

      if (project.status != selectedStatus) {
        await createProjectActivityLog(
          activityType: 'status_changed',
          title:
              'Project status changed from ${_statusLabel(project.status)} to ${_statusLabel(selectedStatus)}',
        );
      }

      await createProjectActivityLog(
        activityType: 'project_updated',
        title: 'Project financials and stage costs were updated.',
      );

      await stageCostService.updateProjectFinancialTotals(
        projectId: project.id,
        contractAmount: savedContractAmount,
        estimatedCost: savedEstimatedTotal,
        actualCost: savedActualTotal + savedMaterialActualTotal,
      );

      await loadProjectDetail();

      if (!mounted) return;

      setState(() {
        isSaving = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString();
        isSaving = false;
      });
    }
  }

  Future<void> saveProjectStatusOnly() async {
    final currentProject = project;
    final previousStatus = currentProject.status;

    setState(() {
      isSaving = true;
      errorMessage = null;
    });

    try {
      await projectService.updateProjectStatus(
        projectId: currentProject.id,
        status: selectedStatus,
      );

      if (previousStatus != selectedStatus) {
        await createProjectActivityLog(
          activityType: 'status_changed',
          title:
              'Project status changed from ${_statusLabel(previousStatus)} to ${_statusLabel(selectedStatus)}',
        );
      }

      await loadProjectDetail();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Project status updated.')));
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString();
      });
    }

    if (!mounted) return;

    setState(() {
      isSaving = false;
    });
  }

  double _calculateEstimatedCost(ProjectStageCost stageCost) {
    if (stageCost.isMilestoneOnly) {
      return 0;
    }

    if (stageCost.stage == 'structure_fabrication' ||
        stageCost.stage == 'sail_fabrication' ||
        stageCost.stage == 'installation') {
      return _laborCost(stageCost.id);
    }

    if (stageCost.stage == 'footers') {
      final laborOrFlatFee = (useFlatFeeValues[stageCost.id] ?? false)
          ? _parseMoney(flatFeeControllers[stageCost.id]?.text ?? '0')
          : _laborCost(stageCost.id);

      final concreteCost =
          _parseInt(
            concreteBagCountControllers[stageCost.id]?.text ?? '0',
          ).toDouble() *
          _parseMoney(concreteBagCostControllers[stageCost.id]?.text ?? '0');

      final rebarCost =
          _parseInt(
            rebarStickCountControllers[stageCost.id]?.text ?? '0',
          ).toDouble() *
          _parseMoney(rebarStickCostControllers[stageCost.id]?.text ?? '0');

      return laborOrFlatFee + concreteCost + rebarCost;
    }

    return _parseMoney(estimatedControllers[stageCost.id]?.text ?? '0');
  }

  double _laborCost(String stageCostId) {
    return _parseInt(peopleControllers[stageCostId]?.text ?? '0').toDouble() *
        _parseMoney(hoursControllers[stageCostId]?.text ?? '0') *
        _parseMoney(hourlyRateControllers[stageCostId]?.text ?? '0');
  }

  double get contractAmount {
    return _parseMoney(contractAmountController.text);
  }

  double get estimatedTotal {
    return stageCosts.fold<double>(
      0,
      (total, stageCost) => total + _calculateEstimatedCost(stageCost),
    );
  }

  double get baseActualTotal {
    return stageCosts.fold<double>(0, (total, stageCost) {
      if (stageCost.isMilestoneOnly) {
        return total;
      }

      return total + _parseMoney(actualControllers[stageCost.id]?.text ?? '0');
    });
  }

  double get additionalActualTotal {
    return stageCostItems.fold<double>(0, (total, item) {
      return total +
          _parseMoney(itemActualCostControllers[item.id]?.text ?? '0');
    });
  }

  double get materialActualTotal {
    return projectMaterials.fold<double>(
      0,
      (total, material) => total + material.totalCost,
    );
  }

  double get actualTotal {
    return baseActualTotal + additionalActualTotal + materialActualTotal;
  }

  double get estimatedProfit {
    return contractAmount - estimatedTotal;
  }

  double get actualProfit {
    return contractAmount - actualTotal;
  }

  double get estimatedMarginPercent {
    if (contractAmount <= 0) {
      return 0;
    }

    return (estimatedProfit / contractAmount) * 100;
  }

  double get actualMarginPercent {
    if (contractAmount <= 0) {
      return 0;
    }

    return (actualProfit / contractAmount) * 100;
  }

  String _statusLabel(String status) {
    return switch (status) {
      'contract' => 'Contract',
      'ordered_material' => 'Ordered Material',
      'structure_fabrication' => 'Structure Fabrication',
      'powder_coating' => 'Powder Coating',
      'footers' => 'Footers',
      'sail_fabrication' => 'Sail Fabrication',
      'installation' => 'Installation',
      'final_invoice' => 'Final Invoice',
      'completed' => 'Completed',
      _ =>
        status
            .replaceAll('_', ' ')
            .split(' ')
            .where((word) => word.isNotEmpty)
            .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
            .join(' '),
    };
  }

  String _materialStatusLabel(String status) {
    return switch (status) {
      'needed' => 'Needed',
      'ordered' => 'Ordered',
      'received' => 'Received',
      'installed' => 'Installed',
      _ =>
        status
            .replaceAll('_', ' ')
            .split(' ')
            .where((word) => word.isNotEmpty)
            .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
            .join(' '),
    };
  }

  Future<ProjectActivityLog?> createProjectActivityLog({
    required String activityType,
    required String title,
    String? body,
  }) async {
    try {
      final activityLog = await projectActivityLogService
          .createProjectActivityLog(
            companyId: widget.companyContext.companyId,
            projectId: project.id,
            activityType: activityType,
            title: title,
            body: body,
          );

      if (!mounted) return activityLog;

      setState(() {
        projectActivityLogs = [activityLog, ...projectActivityLogs];
      });

      return activityLog;
    } catch (_) {
      return null;
    }
  }

  Future<void> addProjectTask() async {
    final createdTask = await showDialog<ProjectTask>(
      context: context,
      builder: (context) {
        return AddProjectTaskDialog(
          assignees: projectTaskAssignees,
          onSave:
              ({
                required title,
                required description,
                required priority,
                required assignedTo,
                required dueDate,
              }) {
                return projectTaskService.createTask(
                  companyId: widget.companyContext.companyId,
                  projectId: project.id,
                  title: title,
                  description: description,
                  priority: priority,
                  assignedTo: assignedTo,
                  dueDate: dueDate,
                );
              },
        );
      },
    );

    if (createdTask == null || !mounted) return;

    setState(() {
      projectTasks = [...projectTasks, createdTask];
    });

    await createProjectActivityLog(
      activityType: 'task_created',
      title: 'Task added: ${createdTask.title}',
      body: createdTask.description,
    );
  }

  Future<void> toggleProjectTask(ProjectTask task) async {
    try {
      final updatedTask = task.isDone
          ? await projectTaskService.reopenTask(task.id)
          : await projectTaskService.markTaskDone(task.id);

      if (!mounted) return;

      setState(() {
        projectTasks = projectTasks
            .map(
              (existingTask) => existingTask.id == updatedTask.id
                  ? updatedTask
                  : existingTask,
            )
            .toList();
      });

      await createProjectActivityLog(
        activityType: updatedTask.isDone ? 'task_completed' : 'task_reopened',
        title: updatedTask.isDone
            ? 'Task completed: ${updatedTask.title}'
            : 'Task reopened: ${updatedTask.title}',
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString();
      });
    }
  }

  Future<void> deleteProjectTask(ProjectTask task) async {
    try {
      await projectTaskService.deleteTask(task.id);

      if (!mounted) return;

      setState(() {
        projectTasks = projectTasks
            .where((existingTask) => existingTask.id != task.id)
            .toList();
      });

      await createProjectActivityLog(
        activityType: 'task_deleted',
        title: 'Task deleted: ${task.title}',
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString();
      });
    }
  }

  Future<void> addProjectMaterial() async {
    final didSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return MaterialDialog(
          canViewCosts: widget.companyContext.canViewFinancials,
          canEditCosts: widget.companyContext.canManageProjectFinancials,
          onSave:
              ({
                required name,
                required category,
                required quantity,
                required unit,
                required unitCost,
                required supplier,
                required status,
              }) async {
                await materialService.createMaterial(
                  companyId: widget.companyContext.companyId,
                  projectId: project.id,
                  name: name,
                  category: category,
                  quantity: quantity,
                  unit: unit,
                  unitCost: unitCost,
                  supplier: supplier,
                  status: status,
                );

                await createProjectActivityLog(
                  activityType: 'material_created',
                  title: 'Material added: $name',
                  body:
                      'Quantity: $quantity $unit • Category: $category • Status: ${_materialStatusLabel(status)}',
                );
              },
        );
      },
    );

    if (didSave != true || !mounted) return;

    await loadProjectDetail();
  }

  Future<void> editProjectMaterial(MaterialItem material) async {
    final didSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return MaterialDialog(
          material: material,
          canViewCosts: widget.companyContext.canViewFinancials,
          canEditCosts: widget.companyContext.canManageProjectFinancials,
          onSave:
              ({
                required name,
                required category,
                required quantity,
                required unit,
                required unitCost,
                required supplier,
                required status,
              }) async {
                await materialService.updateMaterial(
                  id: material.id,
                  name: name,
                  category: category,
                  quantity: quantity,
                  unit: unit,
                  unitCost: unitCost,
                  supplier: supplier,
                  status: status,
                );
              },
        );
      },
    );

    if (didSave != true || !mounted) return;

    await loadProjectDetail();
  }

  Future<void> deleteProjectMaterial(MaterialItem material) async {
    try {
      await materialService.deleteMaterial(material.id);

      if (!mounted) return;

      setState(() {
        projectMaterials = projectMaterials
            .where((existingMaterial) => existingMaterial.id != material.id)
            .toList();
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString();
      });
    }
  }

  Future<void> updateProjectMaterialStatus(
    MaterialItem material,
    String status,
  ) async {
    try {
      await materialService.updateMaterialStatus(
        id: material.id,
        status: status,
      );

      await createProjectActivityLog(
        activityType: 'material_status_changed',
        title: 'Material status changed: ${material.name}',
        body:
            '${_materialStatusLabel(material.status)} → ${_materialStatusLabel(status)}',
      );

      if (!mounted) return;

      await loadProjectDetail();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString();
      });
    }
  }

  Future<void> deleteProjectActivityLog(ProjectActivityLog activityLog) async {
    setState(() {
      isSaving = true;
      errorMessage = null;
    });

    try {
      await projectActivityLogService.deleteProjectActivityLog(activityLog.id);

      if (!mounted) return;

      setState(() {
        projectActivityLogs = projectActivityLogs
            .where((log) => log.id != activityLog.id)
            .toList();
        isSaving = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString();
        isSaving = false;
      });
    }
  }

  Future<void> addProjectNote(String noteType, String body) async {
    final currentProject = project;

    setState(() {
      isSaving = true;
      errorMessage = null;
    });

    try {
      final note = await projectNoteService.createProjectNote(
        companyId: currentProject.companyId,
        projectId: currentProject.id,
        noteType: noteType,
        body: body,
      );

      await createProjectActivityLog(
        activityType: 'note_created',
        title: 'Note added: ${note.noteTypeLabel}',
        body: note.body,
      );

      if (!mounted) return;

      setState(() {
        projectNotes = [note, ...projectNotes];
        isSaving = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString();
        isSaving = false;
      });
    }
  }

  Future<void> deleteProjectNote(ProjectNote note) async {
    setState(() {
      isSaving = true;
      errorMessage = null;
    });

    try {
      await projectNoteService.deleteProjectNote(note.id);

      await createProjectActivityLog(
        activityType: 'note_deleted',
        title: 'Note deleted: ${note.noteTypeLabel}',
      );

      if (!mounted) return;

      setState(() {
        projectNotes = projectNotes
            .where((projectNote) => projectNote.id != note.id)
            .toList();
        isSaving = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString();
        isSaving = false;
      });
    }
  }

  Future<void> uploadProjectFile() async {
    final didUpload = await showDialog<bool>(
      context: context,
      builder: (context) {
        return ProjectFileUploadDialog(
          onUpload:
              ({
                required pickedFile,
                required fileType,
                required description,
              }) async {
                final fileBytes = pickedFile.bytes;

                if (fileBytes == null) {
                  throw Exception('Could not read selected file.');
                }

                await projectFileService.uploadProjectFile(
                  companyId: widget.companyContext.companyId,
                  projectId: project.id,
                  fileName: pickedFile.name,
                  fileBytes: fileBytes,
                  fileType: fileType,
                  mimeType: null,
                  description: description,
                );

                await createProjectActivityLog(
                  activityType: 'file_uploaded',
                  title: 'File uploaded: ${pickedFile.name}',
                  body: description,
                );
              },
        );
      },
    );

    if (didUpload != true || !mounted) return;

    await loadProjectDetail();
  }

  Future<void> openProjectFile(ProjectFile file) async {
    try {
      final signedUrl = await projectFileService.createSignedUrl(file);
      await openProjectFileUrl(signedUrl);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString();
      });
    }
  }

  Future<void> deleteProjectFile(ProjectFile file) async {
    try {
      await projectFileService.deleteProjectFile(file);

      await createProjectActivityLog(
        activityType: 'file_deleted',
        title: 'File deleted: ${file.fileName}',
      );

      if (!mounted) return;

      setState(() {
        projectFiles = projectFiles
            .where((existingFile) => existingFile.id != file.id)
            .toList();
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final canViewProjectFinancials = widget.companyContext.canViewFinancials;
    final canManageProjectFinancials =
        widget.companyContext.canManageProjectFinancials;
    final canCreateMaterials = widget.companyContext.canCreateMaterials;
    final canEditMaterials = widget.companyContext.canEditMaterials;
    final canDeleteMaterials = widget.companyContext.canDeleteMaterials;
    final canUpdateMaterialStatus =
        widget.companyContext.canUpdateMaterialStatus;
    final canUploadProjectFiles = widget.companyContext.canUploadProjectFiles;
    final canDeleteProjectFiles = widget.companyContext.canDeleteProjectFiles;
    final canAddProjectNotes = !widget.companyContext.canViewOnly;
    final canDeleteProjectNotes =
        widget.companyContext.isPrimaryAdmin ||
        widget.companyContext.isCfo ||
        widget.companyContext.isAdmin ||
        widget.companyContext.isManager;
    final canDeleteProjectActivityLogs =
        widget.companyContext.isPrimaryAdmin ||
        widget.companyContext.isCfo ||
        widget.companyContext.isAdmin ||
        widget.companyContext.isManager;
    final canCreateTasks = widget.companyContext.canCreateTasks;
    final canCompleteTasks = widget.companyContext.canCompleteTasks;
    final canDeleteTasks = widget.companyContext.canDeleteTasks;
    final canUpdateProjectStatus = widget.companyContext.canUpdateProjectStatus;

    final content = isLoading
        ? const [
            SliverToBoxAdapter(
              child: _StateCard(
                title: 'Loading project...',
                body: 'Fetching project status, price, and stage costs.',
              ),
            ),
          ]
        : errorMessage != null
        ? [
            SliverToBoxAdapter(
              child: _StateCard(
                title: 'Could not load project',
                body: errorMessage!,
              ),
            ),
          ]
        : [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: _ProjectTitleBlock(project: project),
              ),
            ),
            if (!canViewProjectFinancials)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: _ProjectProgressStatusCard(
                    selectedStatus: selectedStatus,
                    enabled: !isSaving && canUpdateProjectStatus,
                    isSaving: isSaving,
                    onStatusChanged: (value) {
                      if (value == null) return;

                      setState(() {
                        selectedStatus = value;
                      });
                    },
                    onSave: canUpdateProjectStatus
                        ? saveProjectStatusOnly
                        : null,
                  ),
                ),
              ),
            if (canViewProjectFinancials &&
                MediaQuery.of(context).size.shortestSide < 1000)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: _ProjectSummaryCard(
                    contractAmountController: contractAmountController,
                    selectedStatus: selectedStatus,
                    onStatusChanged: isSaving
                        ? null
                        : (value) {
                            if (value == null) return;

                            setState(() {
                              selectedStatus = value;
                            });
                          },
                    estimatedTotal: estimatedTotal,
                    actualTotal: actualTotal,
                    additionalActualTotal: additionalActualTotal,
                    materialActualTotal: materialActualTotal,
                    estimatedProfit: estimatedProfit,
                    actualProfit: actualProfit,
                    estimatedMarginPercent: estimatedMarginPercent,
                    actualMarginPercent: actualMarginPercent,
                    enabled: !isSaving && canManageProjectFinancials,
                    onChanged: () => setState(() {}),
                  ),
                ),
              ),
            if (canViewProjectFinancials &&
                MediaQuery.of(context).size.shortestSide >= 1000)
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickySummaryHeader(
                  child: _ProjectSummaryCard(
                    contractAmountController: contractAmountController,
                    selectedStatus: selectedStatus,
                    onStatusChanged: isSaving
                        ? null
                        : (value) {
                            if (value == null) return;

                            setState(() {
                              selectedStatus = value;
                            });
                          },
                    estimatedTotal: estimatedTotal,
                    actualTotal: actualTotal,
                    additionalActualTotal: additionalActualTotal,
                    materialActualTotal: materialActualTotal,
                    estimatedProfit: estimatedProfit,
                    actualProfit: actualProfit,
                    estimatedMarginPercent: estimatedMarginPercent,
                    actualMarginPercent: actualMarginPercent,
                    enabled: !isSaving && canManageProjectFinancials,
                    onChanged: () => setState(() {}),
                  ),
                ),
              ),
            if (canViewProjectFinancials)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _StageCostsCard(
                    stageCosts: stageCosts,
                    stageCostItems: stageCostItems,
                    descriptionControllers: descriptionControllers,
                    estimatedControllers: estimatedControllers,
                    actualControllers: actualControllers,
                    notesControllers: notesControllers,
                    peopleControllers: peopleControllers,
                    hoursControllers: hoursControllers,
                    hourlyRateControllers: hourlyRateControllers,
                    flatFeeControllers: flatFeeControllers,
                    concreteBagCountControllers: concreteBagCountControllers,
                    concreteBagCostControllers: concreteBagCostControllers,
                    rebarStickCountControllers: rebarStickCountControllers,
                    rebarStickCostControllers: rebarStickCostControllers,
                    anchorBoltCountControllers: anchorBoltCountControllers,
                    anchorBoltCostControllers: anchorBoltCostControllers,
                    fabricYardsControllers: fabricYardsControllers,
                    fabricCostPerYardControllers: fabricCostPerYardControllers,
                    hardwareCountControllers: hardwareCountControllers,
                    hardwareCostEachControllers: hardwareCostEachControllers,
                    cableFeetControllers: cableFeetControllers,
                    cableCostPerFootControllers: cableCostPerFootControllers,
                    itemDescriptionControllers: itemDescriptionControllers,
                    itemActualCostControllers: itemActualCostControllers,
                    completedValues: completedValues,
                    useFlatFeeValues: useFlatFeeValues,
                    concreteUnitTypeValues: concreteUnitTypeValues,
                    fabricTypeValues: fabricTypeValues,
                    enabled: !isSaving,
                    onChanged: () => setState(() {}),
                    onCompletedChanged: (stageCostId, value) {
                      setState(() {
                        completedValues[stageCostId] = value;
                      });
                    },
                    onUseFlatFeeChanged: (stageCostId, value) {
                      setState(() {
                        useFlatFeeValues[stageCostId] = value;
                      });
                    },
                    onConcreteUnitTypeChanged: (stageCostId, value) {
                      setState(() {
                        concreteUnitTypeValues[stageCostId] = value;
                      });
                    },
                    onAddStageCostItem: addStageCostItem,
                    onDeleteStageCostItem: deleteStageCostItem,
                    onAddMiscellaneous: addMiscellaneousExpense,
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: ProjectMaterialsCard(
                  materials: projectMaterials,
                  enabled: !isSaving,
                  canCreateMaterials: canCreateMaterials,
                  canEditMaterials: canEditMaterials,
                  canDeleteMaterials: canDeleteMaterials,
                  canUpdateStatus: canUpdateMaterialStatus,
                  canViewMaterialCosts: canViewProjectFinancials,
                  canEditMaterialCosts: canManageProjectFinancials,
                  onAddMaterial: addProjectMaterial,
                  onEditMaterial: editProjectMaterial,
                  onDeleteMaterial: deleteProjectMaterial,
                  onUpdateMaterialStatus: updateProjectMaterialStatus,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: ProjectFilesCard(
                  files: projectFiles,
                  enabled: !isSaving,
                  canUploadFile: canUploadProjectFiles,
                  canDeleteFile: canDeleteProjectFiles,
                  onUploadFile: uploadProjectFile,
                  onOpenFile: openProjectFile,
                  onDeleteFile: deleteProjectFile,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: ProjectNotesCard(
                  notes: projectNotes,
                  enabled: !isSaving,
                  canAddNote: canAddProjectNotes,
                  canDeleteNote: canDeleteProjectNotes,
                  currentUserId: widget.companyContext.userId,
                  onAddNote: addProjectNote,
                  onDeleteNote: deleteProjectNote,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: ProjectActivityCard(
                  activityLogs: projectActivityLogs,
                  enabled: !isSaving,
                  canDeleteActivity: canDeleteProjectActivityLogs,
                  onDeleteActivity: deleteProjectActivityLog,
                ),
              ),
            ),
            // _ProjectTasksCard_INSERTED_MARKER
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: ProjectTasksCard(
                  tasks: projectTasks,
                  assignees: projectTaskAssignees,
                  enabled: !isSaving,
                  canAddTask: canCreateTasks,
                  canCompleteTask: canCompleteTasks,
                  canDeleteTask: canDeleteTasks,
                  onAddTask: addProjectTask,
                  onToggleTask: toggleProjectTask,
                  onDeleteTask: deleteProjectTask,
                ),
              ),
            ),
            if (errorMessage != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            if (canManageProjectFinancials)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                  child: ElevatedButton(
                    onPressed: isSaving ? null : saveProjectDetail,
                    child: isSaving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save Project Updates'),
                  ),
                ),
              ),
          ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Detail'),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            icon: const Icon(Icons.home_outlined),
            label: const Text('Home'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadProjectDetail,
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: content,
        ),
      ),
    );
  }

  static double _parseMoney(String value) {
    final cleaned = value.replaceAll(',', '').replaceAll('\$', '').trim();

    if (cleaned.isEmpty) {
      return 0;
    }

    return double.tryParse(cleaned) ?? 0;
  }

  static int _parseInt(String value) {
    final cleaned = value.replaceAll(',', '').trim();

    if (cleaned.isEmpty) {
      return 0;
    }

    return int.tryParse(cleaned) ?? 0;
  }

  static String _formatMoneyInput(double value) {
    if (value == 0) {
      return '';
    }

    return value.toStringAsFixed(2);
  }
}

class _ProjectTitleBlock extends StatelessWidget {
  const _ProjectTitleBlock({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          project.projectName,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.7,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          project.projectNumber,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StickySummaryHeader extends SliverPersistentHeaderDelegate {
  const _StickySummaryHeader({required this.child});

  final Widget child;

  @override
  double get minExtent => 255;

  @override
  double get maxExtent => 255;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: const Color(0xFFF3F4F6),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _StickySummaryHeader oldDelegate) {
    return true;
  }
}

class _ProjectProgressStatusCard extends StatelessWidget {
  const _ProjectProgressStatusCard({
    required this.selectedStatus,
    required this.enabled,
    required this.isSaving,
    required this.onStatusChanged,
    required this.onSave,
  });

  final String selectedStatus;
  final bool enabled;
  final bool isSaving;
  final ValueChanged<String?>? onStatusChanged;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    const stageOrder = [
      'contract',
      'ordered_material',
      'structure_fabrication',
      'powder_coating',
      'footers',
      'sail_fabrication',
      'installation',
      'final_invoice',
      'completed',
    ];

    const stageLabels = {
      'contract': 'Contract',
      'ordered_material': 'Ordered Material',
      'structure_fabrication': 'Structure Fabrication',
      'powder_coating': 'Powder Coating',
      'footers': 'Footers',
      'sail_fabrication': 'Sail Fabrication',
      'installation': 'Installation',
      'final_invoice': 'Final Invoice',
      'completed': 'Completed',
    };

    final currentStageIndex = stageOrder.indexOf(selectedStatus);

    return _CardShell(
      title: 'Project Progress / Status Updates',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Update the project stage without changing pricing, costs, or financial totals.',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: selectedStatus,
            decoration: const InputDecoration(labelText: 'Project status'),
            items: const [
              DropdownMenuItem(value: 'contract', child: Text('Contract')),
              DropdownMenuItem(
                value: 'ordered_material',
                child: Text('Ordered Material'),
              ),
              DropdownMenuItem(
                value: 'structure_fabrication',
                child: Text('Structure Fabrication'),
              ),
              DropdownMenuItem(
                value: 'powder_coating',
                child: Text('Powder Coating'),
              ),
              DropdownMenuItem(value: 'footers', child: Text('Footers')),
              DropdownMenuItem(
                value: 'sail_fabrication',
                child: Text('Sail Fabrication'),
              ),
              DropdownMenuItem(
                value: 'installation',
                child: Text('Installation'),
              ),
              DropdownMenuItem(
                value: 'final_invoice',
                child: Text('Final Invoice'),
              ),
              DropdownMenuItem(value: 'completed', child: Text('Completed')),
            ],
            onChanged: enabled ? onStatusChanged : null,
          ),
          const SizedBox(height: 16),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Project Stages',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var index = 0; index < stageOrder.length; index++)
                _ProjectStagePill(
                  label: stageLabels[stageOrder[index]] ?? stageOrder[index],
                  isCurrent: index == currentStageIndex,
                  isPast: currentStageIndex >= 0 && index < currentStageIndex,
                ),
            ],
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: enabled ? onSave : null,
            child: isSaving
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Save Status Update'),
          ),
          if (!enabled && onSave == null) ...[
            const SizedBox(height: 10),
            const Text(
              'Your role can view project status but cannot update it.',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProjectStagePill extends StatelessWidget {
  const _ProjectStagePill({
    required this.label,
    required this.isCurrent,
    required this.isPast,
  });

  final String label;
  final bool isCurrent;
  final bool isPast;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isCurrent
        ? const Color(0xFFDBEAFE)
        : isPast
        ? const Color(0xFFECFDF5)
        : const Color(0xFFF8FAFC);

    final borderColor = isCurrent
        ? const Color(0xFF2563EB)
        : isPast
        ? const Color(0xFF10B981)
        : const Color(0xFFE2E8F0);

    final textColor = isCurrent
        ? const Color(0xFF1D4ED8)
        : isPast
        ? const Color(0xFF047857)
        : const Color(0xFF64748B);

    final icon = isCurrent
        ? Icons.radio_button_checked
        : isPast
        ? Icons.check_circle_outline
        : Icons.radio_button_unchecked;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectSummaryCard extends StatelessWidget {
  const _ProjectSummaryCard({
    required this.contractAmountController,
    required this.selectedStatus,
    required this.onStatusChanged,
    required this.estimatedTotal,
    required this.actualTotal,
    required this.additionalActualTotal,
    required this.materialActualTotal,
    required this.estimatedProfit,
    required this.actualProfit,
    required this.estimatedMarginPercent,
    required this.actualMarginPercent,
    required this.enabled,
    required this.onChanged,
  });

  final TextEditingController contractAmountController;
  final String selectedStatus;
  final ValueChanged<String?>? onStatusChanged;
  final double estimatedTotal;
  final double actualTotal;
  final double additionalActualTotal;
  final double materialActualTotal;
  final double estimatedProfit;
  final double actualProfit;
  final double estimatedMarginPercent;
  final double actualMarginPercent;
  final bool enabled;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      title: 'Project Price, Status & Totals',
      child: Column(
        children: [
          TextFormField(
            controller: contractAmountController,
            enabled: enabled,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Project price / contract amount',
              prefixText: '\$',
            ),
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: selectedStatus,
            decoration: const InputDecoration(labelText: 'Project status'),
            items: const [
              DropdownMenuItem(value: 'contract', child: Text('Contract')),
              DropdownMenuItem(
                value: 'ordered_material',
                child: Text('Ordered Material'),
              ),
              DropdownMenuItem(
                value: 'structure_fabrication',
                child: Text('Structure Fabrication'),
              ),
              DropdownMenuItem(
                value: 'powder_coating',
                child: Text('Powder Coating'),
              ),
              DropdownMenuItem(value: 'footers', child: Text('Footers')),
              DropdownMenuItem(
                value: 'sail_fabrication',
                child: Text('Sail Fabrication'),
              ),
              DropdownMenuItem(
                value: 'installation',
                child: Text('Installation'),
              ),
              DropdownMenuItem(
                value: 'final_invoice',
                child: Text('Final Invoice'),
              ),
              DropdownMenuItem(value: 'completed', child: Text('Completed')),
            ],
            onChanged: enabled ? onStatusChanged : null,
          ),
          const SizedBox(height: 14),
          _MoneyGrid(
            estimatedTotal: estimatedTotal,
            actualTotal: actualTotal,
            additionalActualTotal: additionalActualTotal,
            materialActualTotal: materialActualTotal,
            estimatedProfit: estimatedProfit,
            actualProfit: actualProfit,
            estimatedMarginPercent: estimatedMarginPercent,
            actualMarginPercent: actualMarginPercent,
          ),
        ],
      ),
    );
  }
}

class _MoneyGrid extends StatelessWidget {
  const _MoneyGrid({
    required this.estimatedTotal,
    required this.actualTotal,
    required this.additionalActualTotal,
    required this.materialActualTotal,
    required this.estimatedProfit,
    required this.actualProfit,
    required this.estimatedMarginPercent,
    required this.actualMarginPercent,
  });

  final double estimatedTotal;
  final double actualTotal;
  final double additionalActualTotal;
  final double materialActualTotal;
  final double estimatedProfit;
  final double actualProfit;
  final double estimatedMarginPercent;
  final double actualMarginPercent;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bucketWidth = constraints.maxWidth < 520
            ? (constraints.maxWidth - 10) / 2
            : 155.0;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _ColoredMetricBucket(
              width: bucketWidth,
              label: 'Projected Cost',
              value: _formatMoney(estimatedTotal),
              backgroundColor: const Color(0xFFEFF6FF),
              borderColor: const Color(0xFF2563EB),
              textColor: const Color(0xFF1D4ED8),
            ),
            _ColoredMetricBucket(
              width: bucketWidth,
              label: 'Projected Profit',
              value: _formatMoney(estimatedProfit),
              backgroundColor: const Color(0xFFEFF6FF),
              borderColor: const Color(0xFF2563EB),
              textColor: const Color(0xFF1D4ED8),
            ),
            _ColoredMetricBucket(
              width: bucketWidth,
              label: 'Projected Margin',
              value: '${estimatedMarginPercent.toStringAsFixed(1)}%',
              backgroundColor: const Color(0xFFEFF6FF),
              borderColor: const Color(0xFF2563EB),
              textColor: const Color(0xFF1D4ED8),
            ),
            _ColoredMetricBucket(
              width: bucketWidth,
              label: 'Added Expenses',
              value: _formatMoney(additionalActualTotal),
              backgroundColor: const Color(0xFFFFF7ED),
              borderColor: const Color(0xFFF97316),
              textColor: const Color(0xFFC2410C),
            ),
            _ColoredMetricBucket(
              width: bucketWidth,
              label: 'Actual Cost',
              value: _formatMoney(actualTotal),
              backgroundColor: const Color(0xFFF0FDF4),
              borderColor: const Color(0xFF16A34A),
              textColor: const Color(0xFF15803D),
            ),
            _ColoredMetricBucket(
              width: bucketWidth,
              label: 'Actual Profit',
              value: _formatMoney(actualProfit),
              backgroundColor: const Color(0xFFF0FDF4),
              borderColor: const Color(0xFF16A34A),
              textColor: const Color(0xFF15803D),
            ),
            _ColoredMetricBucket(
              width: bucketWidth,
              label: 'Actual Margin',
              value: '${actualMarginPercent.toStringAsFixed(1)}%',
              backgroundColor: const Color(0xFFF0FDF4),
              borderColor: const Color(0xFF16A34A),
              textColor: const Color(0xFF15803D),
            ),
          ],
        );
      },
    );
  }

  static String _formatMoney(double value) {
    final sign = value < 0 ? '-' : '';
    return '$sign\$${value.abs().toStringAsFixed(2)}';
  }
}

class _ColoredMetricBucket extends StatelessWidget {
  const _ColoredMetricBucket({
    required this.label,
    required this.value,
    required this.width,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });

  final String label;
  final String value;
  final double width;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textColor,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textColor,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _StageCostsCard extends StatelessWidget {
  const _StageCostsCard({
    required this.stageCosts,
    required this.stageCostItems,
    required this.descriptionControllers,
    required this.estimatedControllers,
    required this.actualControllers,
    required this.notesControllers,
    required this.peopleControllers,
    required this.hoursControllers,
    required this.hourlyRateControllers,
    required this.flatFeeControllers,
    required this.concreteBagCountControllers,
    required this.concreteBagCostControllers,
    required this.rebarStickCountControllers,
    required this.rebarStickCostControllers,
    required this.anchorBoltCountControllers,
    required this.anchorBoltCostControllers,
    required this.fabricYardsControllers,
    required this.fabricCostPerYardControllers,
    required this.hardwareCountControllers,
    required this.hardwareCostEachControllers,
    required this.cableFeetControllers,
    required this.cableCostPerFootControllers,
    required this.itemDescriptionControllers,
    required this.itemActualCostControllers,
    required this.completedValues,
    required this.useFlatFeeValues,
    required this.concreteUnitTypeValues,
    required this.fabricTypeValues,
    required this.enabled,
    required this.onChanged,
    required this.onCompletedChanged,
    required this.onUseFlatFeeChanged,
    required this.onConcreteUnitTypeChanged,
    required this.onAddStageCostItem,
    required this.onDeleteStageCostItem,
    required this.onAddMiscellaneous,
  });

  final List<ProjectStageCost> stageCosts;
  final List<ProjectStageCostItem> stageCostItems;
  final Map<String, TextEditingController> descriptionControllers;
  final Map<String, TextEditingController> estimatedControllers;
  final Map<String, TextEditingController> actualControllers;
  final Map<String, TextEditingController> notesControllers;
  final Map<String, TextEditingController> peopleControllers;
  final Map<String, TextEditingController> hoursControllers;
  final Map<String, TextEditingController> hourlyRateControllers;
  final Map<String, TextEditingController> flatFeeControllers;
  final Map<String, TextEditingController> concreteBagCountControllers;
  final Map<String, TextEditingController> concreteBagCostControllers;
  final Map<String, TextEditingController> rebarStickCountControllers;
  final Map<String, TextEditingController> rebarStickCostControllers;
  final Map<String, TextEditingController> anchorBoltCountControllers;
  final Map<String, TextEditingController> anchorBoltCostControllers;
  final Map<String, TextEditingController> fabricYardsControllers;
  final Map<String, TextEditingController> fabricCostPerYardControllers;
  final Map<String, TextEditingController> hardwareCountControllers;
  final Map<String, TextEditingController> hardwareCostEachControllers;
  final Map<String, TextEditingController> cableFeetControllers;
  final Map<String, TextEditingController> cableCostPerFootControllers;
  final Map<String, TextEditingController> itemDescriptionControllers;
  final Map<String, TextEditingController> itemActualCostControllers;
  final Map<String, bool> completedValues;
  final Map<String, bool> useFlatFeeValues;
  final Map<String, String> concreteUnitTypeValues;
  final Map<String, String?> fabricTypeValues;
  final bool enabled;
  final VoidCallback onChanged;
  final void Function(String stageCostId, bool value) onCompletedChanged;
  final void Function(String stageCostId, bool value) onUseFlatFeeChanged;
  final void Function(String stageCostId, String value)
  onConcreteUnitTypeChanged;
  final ValueChanged<ProjectStageCost> onAddStageCostItem;
  final ValueChanged<ProjectStageCostItem> onDeleteStageCostItem;
  final VoidCallback onAddMiscellaneous;

  @override
  Widget build(BuildContext context) {
    final visibleStages = stageCosts
        .where((stageCost) => !stageCost.isMilestoneOnly)
        .toList();

    return _CardShell(
      title: 'Stage Line Items',
      child: Column(
        children: [
          if (visibleStages.isEmpty)
            const Text(
              'No cost rows found for this project.',
              style: TextStyle(
                color: Color(0xFF4B5563),
                fontSize: 15,
                height: 1.45,
              ),
            )
          else
            ...visibleStages.map((stageCost) {
              final itemsForStage = stageCostItems
                  .where((item) => item.stageCostId == stageCost.id)
                  .toList();

              return _StageCostRow(
                stageCost: stageCost,
                stageCostItems: itemsForStage,
                descriptionController: descriptionControllers.putIfAbsent(
                  stageCost.id,
                  () => TextEditingController(),
                ),
                estimatedController: estimatedControllers.putIfAbsent(
                  stageCost.id,
                  () => TextEditingController(),
                ),
                actualController: actualControllers.putIfAbsent(
                  stageCost.id,
                  () => TextEditingController(),
                ),
                notesController: notesControllers.putIfAbsent(
                  stageCost.id,
                  () => TextEditingController(),
                ),
                peopleController: peopleControllers.putIfAbsent(
                  stageCost.id,
                  () => TextEditingController(),
                ),
                hoursController: hoursControllers.putIfAbsent(
                  stageCost.id,
                  () => TextEditingController(),
                ),
                hourlyRateController: hourlyRateControllers.putIfAbsent(
                  stageCost.id,
                  () => TextEditingController(),
                ),
                flatFeeController: flatFeeControllers.putIfAbsent(
                  stageCost.id,
                  () => TextEditingController(),
                ),
                concreteBagCountController: concreteBagCountControllers
                    .putIfAbsent(stageCost.id, () => TextEditingController()),
                concreteBagCostController: concreteBagCostControllers
                    .putIfAbsent(stageCost.id, () => TextEditingController()),
                rebarStickCountController: rebarStickCountControllers
                    .putIfAbsent(stageCost.id, () => TextEditingController()),
                rebarStickCostController: rebarStickCostControllers.putIfAbsent(
                  stageCost.id,
                  () => TextEditingController(),
                ),
                anchorBoltCountController: anchorBoltCountControllers
                    .putIfAbsent(stageCost.id, () => TextEditingController()),
                anchorBoltCostController: anchorBoltCostControllers.putIfAbsent(
                  stageCost.id,
                  () => TextEditingController(),
                ),
                fabricYardsController: fabricYardsControllers.putIfAbsent(
                  stageCost.id,
                  () => TextEditingController(),
                ),
                fabricCostPerYardController: fabricCostPerYardControllers
                    .putIfAbsent(stageCost.id, () => TextEditingController()),
                hardwareCountController: hardwareCountControllers.putIfAbsent(
                  stageCost.id,
                  () => TextEditingController(),
                ),
                hardwareCostEachController: hardwareCostEachControllers
                    .putIfAbsent(stageCost.id, () => TextEditingController()),
                cableFeetController: cableFeetControllers.putIfAbsent(
                  stageCost.id,
                  () => TextEditingController(),
                ),
                cableCostPerFootController: cableCostPerFootControllers
                    .putIfAbsent(stageCost.id, () => TextEditingController()),
                itemDescriptionControllers: itemDescriptionControllers,
                itemActualCostControllers: itemActualCostControllers,
                isCompleted: completedValues[stageCost.id] ?? false,
                useFlatFee: useFlatFeeValues[stageCost.id] ?? false,
                concreteUnitType: concreteUnitTypeValues[stageCost.id] ?? 'bag',
                fabricType: fabricTypeValues[stageCost.id],
                enabled: enabled,
                onChanged: onChanged,
                onCompletedChanged: (value) {
                  onCompletedChanged(stageCost.id, value);
                },
                onUseFlatFeeChanged: (value) {
                  onUseFlatFeeChanged(stageCost.id, value);
                },
                onConcreteUnitTypeChanged: (value) {
                  onConcreteUnitTypeChanged(stageCost.id, value);
                },
                onFabricTypeChanged: (value) {
                  fabricTypeValues[stageCost.id] = value;
                  onChanged();
                },
                onAddExpense: () {
                  onAddStageCostItem(stageCost);
                },
                onDeleteExpense: onDeleteStageCostItem,
              );
            }),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: enabled ? onAddMiscellaneous : null,
              icon: const Icon(Icons.add),
              label: const Text('Add Miscellaneous Expense'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StageCostRow extends StatelessWidget {
  const _StageCostRow({
    required this.stageCost,
    required this.stageCostItems,
    required this.descriptionController,
    required this.estimatedController,
    required this.actualController,
    required this.notesController,
    required this.peopleController,
    required this.hoursController,
    required this.hourlyRateController,
    required this.flatFeeController,
    required this.concreteBagCountController,
    required this.concreteBagCostController,
    required this.rebarStickCountController,
    required this.rebarStickCostController,
    required this.anchorBoltCountController,
    required this.anchorBoltCostController,
    required this.fabricYardsController,
    required this.fabricCostPerYardController,
    required this.hardwareCountController,
    required this.hardwareCostEachController,
    required this.cableFeetController,
    required this.cableCostPerFootController,
    required this.itemDescriptionControllers,
    required this.itemActualCostControllers,
    required this.isCompleted,
    required this.useFlatFee,
    required this.concreteUnitType,
    required this.fabricType,
    required this.enabled,
    required this.onChanged,
    required this.onCompletedChanged,
    required this.onUseFlatFeeChanged,
    required this.onConcreteUnitTypeChanged,
    required this.onFabricTypeChanged,
    required this.onAddExpense,
    required this.onDeleteExpense,
  });

  final ProjectStageCost stageCost;
  final List<ProjectStageCostItem> stageCostItems;
  final TextEditingController descriptionController;
  final TextEditingController estimatedController;
  final TextEditingController actualController;
  final TextEditingController notesController;
  final TextEditingController peopleController;
  final TextEditingController hoursController;
  final TextEditingController hourlyRateController;
  final TextEditingController flatFeeController;
  final TextEditingController concreteBagCountController;
  final TextEditingController concreteBagCostController;
  final TextEditingController rebarStickCountController;
  final TextEditingController rebarStickCostController;
  final TextEditingController anchorBoltCountController;
  final TextEditingController anchorBoltCostController;
  final TextEditingController fabricYardsController;
  final TextEditingController fabricCostPerYardController;
  final TextEditingController hardwareCountController;
  final TextEditingController hardwareCostEachController;
  final TextEditingController cableFeetController;
  final TextEditingController cableCostPerFootController;
  final Map<String, TextEditingController> itemDescriptionControllers;
  final Map<String, TextEditingController> itemActualCostControllers;
  final bool isCompleted;
  final bool useFlatFee;
  final String concreteUnitType;
  final String? fabricType;
  final bool enabled;
  final VoidCallback onChanged;
  final ValueChanged<bool> onCompletedChanged;
  final ValueChanged<bool> onUseFlatFeeChanged;
  final ValueChanged<String> onConcreteUnitTypeChanged;
  final ValueChanged<String?> onFabricTypeChanged;
  final VoidCallback onAddExpense;
  final ValueChanged<ProjectStageCostItem> onDeleteExpense;

  int get stageColorIndex {
    switch (stageCost.stage) {
      case 'ordered_material':
        return 0;
      case 'structure_fabrication':
        return 1;
      case 'powder_coating':
        return 2;
      case 'equipment':
        return 3;
      case 'footers':
        return 4;
      case 'sail_fabrication':
        return 5;
      case 'installation':
        return 6;
      case 'miscellaneous':
        return 7;
      default:
        return 0;
    }
  }

  Color get stageShellColor {
    const colors = [
      Color(0xFFE5E7EB),
      Color(0xFFD8DEE8),
      Color(0xFFCBD5E1),
      Color(0xFFB8C4D3),
      Color(0xFFA7B4C5),
      Color(0xFF95A4B8),
      Color(0xFF8494AA),
      Color(0xFF72849B),
    ];

    return colors[stageColorIndex];
  }

  Color get stageInnerColor {
    return const Color(0xFFF8FAFC);
  }

  Color get stageBorderColor {
    const colors = [
      Color(0xFF64748B),
      Color(0xFF475569),
      Color(0xFF334155),
      Color(0xFF1E40AF),
      Color(0xFF0E7490),
      Color(0xFF15803D),
      Color(0xFFB45309),
      Color(0xFFBE123C),
    ];

    return colors[stageColorIndex];
  }

  Color get stageTitleColor {
    const colors = [
      Color(0xFF334155),
      Color(0xFF1F2937),
      Color(0xFF111827),
      Color(0xFF1D4ED8),
      Color(0xFF0E7490),
      Color(0xFF15803D),
      Color(0xFFB45309),
      Color(0xFFBE123C),
    ];

    return colors[stageColorIndex];
  }

  Color get _lupinusStageShellColor {
    switch (stageCost.stage) {
      case 'ordered_material':
        return const Color(0xFFFFEDD5); // orange shell
      case 'structure_fabrication':
        return const Color(0xFFDBEAFE); // blue shell
      case 'powder_coating':
        return const Color(0xFFEDE9FE); // purple shell
      case 'equipment':
        return const Color(0xFFFCE7F3); // pink shell
      case 'footers':
        return const Color(0xFFCFFAFE); // cyan shell
      case 'sail_fabrication':
        return const Color(0xFFDCFCE7); // green shell
      case 'installation':
        return const Color(0xFFFEF3C7); // amber shell
      case 'miscellaneous':
        return const Color(0xFFE7E5E4); // stone shell
      default:
        return const Color(0xFFE5E7EB);
    }
  }

  Color get _lupinusStageHeaderColor {
    switch (stageCost.stage) {
      case 'ordered_material':
        return const Color(0xFFC2410C);
      case 'structure_fabrication':
        return const Color(0xFF1D4ED8);
      case 'powder_coating':
        return const Color(0xFF6D28D9);
      case 'equipment':
        return const Color(0xFFBE185D);
      case 'footers':
        return const Color(0xFF0E7490);
      case 'sail_fabrication':
        return const Color(0xFF15803D);
      case 'installation':
        return const Color(0xFFB45309);
      case 'miscellaneous':
        return const Color(0xFF44403C);
      default:
        return const Color(0xFF0F172A);
    }
  }

  String get _lupinusStageTitle {
    if (stageCost.isMiscellaneous) {
      return 'MISCELLANEOUS EXPENSE';
    }

    return stageCost.stageLabel.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isLaborStage =
        stageCost.stage == 'structure_fabrication' ||
        stageCost.stage == 'sail_fabrication' ||
        stageCost.stage == 'installation';

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _lupinusStageShellColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // _LUPINUS_STAGE_VISUAL_HEADER
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _lupinusStageHeaderColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x24000000),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Text(
              _lupinusStageTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ),

          if (stageCost.isMiscellaneous)
            TextFormField(
              controller: descriptionController,
              enabled: enabled,
              decoration: const InputDecoration(
                labelText: 'Miscellaneous description',
              ),
            )
          else
            const SizedBox.shrink(),
          const SizedBox(height: 12),
          if (isLaborStage) ...[
            _LaborInputs(
              peopleController: peopleController,
              hoursController: hoursController,
              hourlyRateController: hourlyRateController,
              enabled: enabled,
              onChanged: onChanged,
              hoursLabel: stageCost.stage == 'sail_fabrication'
                  ? 'Hours each'
                  : 'Hours each',
            ),
            if (stageCost.stage == 'sail_fabrication') ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: fabricType,
                decoration: const InputDecoration(labelText: 'Fabric type'),
                items: const [
                  DropdownMenuItem(value: 'GP 340', child: Text('GP 340')),
                  DropdownMenuItem(value: 'GP 430', child: Text('GP 430')),
                  DropdownMenuItem(
                    value: 'Sunbrella',
                    child: Text('Sunbrella'),
                  ),
                  DropdownMenuItem(
                    value: 'Serge Ferrari',
                    child: Text('Serge Ferrari'),
                  ),
                  DropdownMenuItem(value: 'Custom', child: Text('Custom')),
                ],
                onChanged: enabled ? onFabricTypeChanged : null,
              ),
            ],
          ] else if (stageCost.stage == 'footers') ...[
            Material(
              color: Colors.transparent,
              child: SwitchListTile(
                value: useFlatFee,
                onChanged: enabled ? onUseFlatFeeChanged : null,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Use flat fee for footer labor',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            if (useFlatFee)
              TextFormField(
                controller: flatFeeController,
                enabled: enabled,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Footer labor flat fee',
                  prefixText: '\$',
                ),
                onChanged: (_) => onChanged(),
              )
            else
              _LaborInputs(
                peopleController: peopleController,
                hoursController: hoursController,
                hourlyRateController: hourlyRateController,
                enabled: enabled,
                onChanged: onChanged,
                hoursLabel: 'Hours each',
              ),
            if (!useFlatFee) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: concreteUnitType,
                decoration: const InputDecoration(labelText: 'Concrete unit'),
                items: const [
                  DropdownMenuItem(value: 'bag', child: Text('Bags')),
                  DropdownMenuItem(value: 'pallet', child: Text('Pallets')),
                ],
                onChanged: enabled
                    ? (value) {
                        if (value == null) return;
                        onConcreteUnitTypeChanged(value);
                      }
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: concreteBagCountController,
                enabled: enabled,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: concreteUnitType == 'pallet'
                      ? 'Concrete pallets'
                      : 'Concrete bags',
                ),
                onChanged: (_) => onChanged(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: concreteBagCostController,
                enabled: enabled,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: concreteUnitType == 'pallet'
                      ? 'Cost per pallet'
                      : 'Cost per bag',
                  prefixText: '\$',
                ),
                onChanged: (_) => onChanged(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: rebarStickCountController,
                enabled: enabled,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Sticks of rebar'),
                onChanged: (_) => onChanged(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: rebarStickCostController,
                enabled: enabled,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cost per rebar stick',
                  prefixText: '\$',
                ),
                onChanged: (_) => onChanged(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: anchorBoltCountController,
                enabled: enabled,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Anchor bolts / nuts amount',
                ),
                onChanged: (_) => onChanged(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: anchorBoltCostController,
                enabled: enabled,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cost per anchor bolt / nut',
                  prefixText: '\$',
                ),
                onChanged: (_) => onChanged(),
              ),
            ],
          ] else ...[
            TextFormField(
              controller: estimatedController,
              enabled: enabled,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Estimated cost',
                prefixText: '\$',
              ),
              onChanged: (_) => onChanged(),
            ),
          ],
          const SizedBox(height: 12),
          _StageCalculatedTotals(
            stageCost: stageCost,
            peopleController: peopleController,
            hoursController: hoursController,
            hourlyRateController: hourlyRateController,
            flatFeeController: flatFeeController,
            concreteBagCountController: concreteBagCountController,
            concreteBagCostController: concreteBagCostController,
            rebarStickCountController: rebarStickCountController,
            rebarStickCostController: rebarStickCostController,
            anchorBoltCountController: anchorBoltCountController,
            anchorBoltCostController: anchorBoltCostController,
            fabricYardsController: fabricYardsController,
            fabricCostPerYardController: fabricCostPerYardController,
            hardwareCountController: hardwareCountController,
            hardwareCostEachController: hardwareCostEachController,
            cableFeetController: cableFeetController,
            cableCostPerFootController: cableCostPerFootController,
            estimatedController: estimatedController,
            useFlatFee: useFlatFee,
            concreteUnitType: concreteUnitType,
          ),
          const SizedBox(height: 12),
          _AdditionalExpenseRows(
            items: stageCostItems,
            descriptionControllers: itemDescriptionControllers,
            actualCostControllers: itemActualCostControllers,
            enabled: enabled,
            onChanged: onChanged,
            onAddExpense: onAddExpense,
            onDeleteExpense: onDeleteExpense,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: actualController,
            enabled: enabled,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Actual cost',
              prefixText: '\$',
            ),
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: notesController,
            enabled: enabled,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Notes',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 8),
          Material(
            color: Colors.transparent,
            child: CheckboxListTile(
              value: isCompleted,
              onChanged: enabled
                  ? (value) {
                      onCompletedChanged(value ?? false);
                    }
                  : null,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Stage completed',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdditionalExpenseRows extends StatelessWidget {
  const _AdditionalExpenseRows({
    required this.items,
    required this.descriptionControllers,
    required this.actualCostControllers,
    required this.enabled,
    required this.onChanged,
    required this.onAddExpense,
    required this.onDeleteExpense,
  });

  final List<ProjectStageCostItem> items;
  final Map<String, TextEditingController> descriptionControllers;
  final Map<String, TextEditingController> actualCostControllers;
  final bool enabled;
  final VoidCallback onChanged;
  final VoidCallback onAddExpense;
  final ValueChanged<ProjectStageCostItem> onDeleteExpense;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Additional Actual Costs',
            style: TextStyle(
              color: Color(0xFF111827),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            const Text(
              'No additional actual costs added.',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 13,
                height: 1.4,
              ),
            )
          else
            ...items.map(
              (item) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: descriptionControllers[item.id],
                      enabled: enabled,
                      decoration: const InputDecoration(
                        labelText: 'Expense description',
                      ),
                      onChanged: (_) => onChanged(),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: actualCostControllers[item.id],
                      enabled: enabled,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Actual cost',
                        prefixText: '\$',
                      ),
                      onChanged: (_) => onChanged(),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: enabled ? () => onDeleteExpense(item) : null,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete Expense'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: enabled ? onAddExpense : null,
              icon: const Icon(Icons.add),
              label: const Text('Add Expense'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StageCalculatedTotals extends StatelessWidget {
  const _StageCalculatedTotals({
    required this.stageCost,
    required this.peopleController,
    required this.hoursController,
    required this.hourlyRateController,
    required this.flatFeeController,
    required this.concreteBagCountController,
    required this.concreteBagCostController,
    required this.rebarStickCountController,
    required this.rebarStickCostController,
    required this.anchorBoltCountController,
    required this.anchorBoltCostController,
    required this.fabricYardsController,
    required this.fabricCostPerYardController,
    required this.hardwareCountController,
    required this.hardwareCostEachController,
    required this.cableFeetController,
    required this.cableCostPerFootController,
    required this.estimatedController,
    required this.useFlatFee,
    required this.concreteUnitType,
  });

  final ProjectStageCost stageCost;
  final TextEditingController peopleController;
  final TextEditingController hoursController;
  final TextEditingController hourlyRateController;
  final TextEditingController flatFeeController;
  final TextEditingController concreteBagCountController;
  final TextEditingController concreteBagCostController;
  final TextEditingController rebarStickCountController;
  final TextEditingController rebarStickCostController;
  final TextEditingController anchorBoltCountController;
  final TextEditingController anchorBoltCostController;
  final TextEditingController fabricYardsController;
  final TextEditingController fabricCostPerYardController;
  final TextEditingController hardwareCountController;
  final TextEditingController hardwareCostEachController;
  final TextEditingController cableFeetController;
  final TextEditingController cableCostPerFootController;
  final TextEditingController estimatedController;
  final bool useFlatFee;
  final String concreteUnitType;

  @override
  Widget build(BuildContext context) {
    final people = _parseInt(peopleController.text);
    final hoursEach = _parseMoney(hoursController.text);
    final costPerHour = _parseMoney(hourlyRateController.text);

    final laborTotal = people.toDouble() * hoursEach * costPerHour;

    final flatFee = _parseMoney(flatFeeController.text);

    final concreteBags = _parseInt(concreteBagCountController.text);
    final concreteCostPerBag = _parseMoney(concreteBagCostController.text);
    final concreteTotal = concreteBags.toDouble() * concreteCostPerBag;

    final rebarSticks = _parseInt(rebarStickCountController.text);
    final rebarCostPerStick = _parseMoney(rebarStickCostController.text);
    final rebarTotal = rebarSticks.toDouble() * rebarCostPerStick;

    final anchorBoltCount = _parseInt(anchorBoltCountController.text);
    final anchorBoltCost = _parseMoney(anchorBoltCostController.text);
    final anchorBoltTotal = anchorBoltCount.toDouble() * anchorBoltCost;

    final fabricYards = _parseMoney(fabricYardsController.text);
    final fabricCostPerYard = _parseMoney(fabricCostPerYardController.text);
    final fabricTotal = fabricYards * fabricCostPerYard;

    final hardwareCount = _parseInt(hardwareCountController.text);
    final hardwareCostEach = _parseMoney(hardwareCostEachController.text);
    final hardwareTotal = hardwareCount.toDouble() * hardwareCostEach;

    final cableFeet = _parseMoney(cableFeetController.text);
    final cableCostPerFoot = _parseMoney(cableCostPerFootController.text);
    final cableTotal = cableFeet * cableCostPerFoot;

    final sailMaterialTotal = fabricTotal + hardwareTotal + cableTotal;

    final standardEstimated = _parseMoney(estimatedController.text);

    double stageTotal = standardEstimated;

    if (stageCost.stage == 'structure_fabrication' ||
        stageCost.stage == 'installation') {
      stageTotal = laborTotal;
    }

    if (stageCost.stage == 'sail_fabrication') {
      stageTotal = laborTotal + sailMaterialTotal;
    }

    if (stageCost.stage == 'footers') {
      stageTotal = useFlatFee
          ? flatFee
          : laborTotal + concreteTotal + rebarTotal + anchorBoltTotal;
    }

    if (stageCost.isMiscellaneous) {
      stageTotal = standardEstimated;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Calculated Total',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          if (stageCost.stage == 'structure_fabrication' ||
              stageCost.stage == 'sail_fabrication') ...[
            _CalcLine(label: 'Labor subtotal', value: laborTotal),
          ] else if (stageCost.stage == 'footers') ...[
            if (useFlatFee)
              _CalcLine(label: 'Footer labor flat fee', value: flatFee)
            else ...[
              _CalcLine(label: 'Footer labor subtotal', value: laborTotal),
              _CalcLine(
                label: concreteUnitType == 'pallet'
                    ? 'Concrete pallet subtotal'
                    : 'Concrete bag subtotal',
                value: concreteTotal,
              ),
              _CalcLine(label: 'Rebar subtotal', value: rebarTotal),
              _CalcLine(
                label: 'Anchor bolts / nuts subtotal',
                value: anchorBoltTotal,
              ),
            ],
          ] else ...[
            _CalcLine(label: 'Estimated subtotal', value: standardEstimated),
          ],
          const Divider(height: 18),
          _CalcLine(
            label: 'Stage estimated total',
            value: stageTotal,
            isBold: true,
          ),
        ],
      ),
    );
  }

  static double _parseMoney(String value) {
    final cleaned = value.replaceAll(',', '').replaceAll('\$', '').trim();

    if (cleaned.isEmpty) {
      return 0;
    }

    return double.tryParse(cleaned) ?? 0;
  }

  static int _parseInt(String value) {
    final cleaned = value.replaceAll(',', '').trim();

    if (cleaned.isEmpty) {
      return 0;
    }

    return int.tryParse(cleaned) ?? 0;
  }
}

class _CalcLine extends StatelessWidget {
  const _CalcLine({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  final String label;
  final double value;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: const Color(0xFF4B5563),
                fontSize: 13,
                fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ),
          Text(
            '\$${value.toStringAsFixed(2)}',
            style: TextStyle(
              color: const Color(0xFF111827),
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LaborInputs extends StatelessWidget {
  const _LaborInputs({
    required this.peopleController,
    required this.hoursController,
    required this.hourlyRateController,
    required this.enabled,
    required this.onChanged,
    required this.hoursLabel,
  });

  final TextEditingController peopleController;
  final TextEditingController hoursController;
  final TextEditingController hourlyRateController;
  final bool enabled;
  final VoidCallback onChanged;
  final String hoursLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: peopleController,
          enabled: enabled,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Number of employees'),
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: hoursController,
          enabled: enabled,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: hoursLabel),
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: hourlyRateController,
          enabled: enabled,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Cost per hour',
            prefixText: '\$',
          ),
          onChanged: (_) => onChanged(),
        ),
      ],
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      title: title,
      child: Text(
        body,
        style: const TextStyle(
          color: Color(0xFF4B5563),
          fontSize: 15,
          height: 1.45,
        ),
      ),
    );
  }
}
