<?php
session_start();
require_once __DIR__ . '/../config/database.php';

if (!isset($_SESSION['user_id']) || $_SESSION['user_type'] !== 'doctor') {
    header('Location: login.php');
    exit;
}

$pdo = getDatabaseConnection();

// Get doctor ID
$stmt = $pdo->prepare("SELECT id FROM doctors WHERE user_id = ?");
$stmt->execute([$_SESSION['user_id']]);
$doctor = $stmt->fetch();
$doctor_id = $doctor['id'];

// Handle appointment completion
if (isset($_GET['complete']) && isset($_GET['id'])) {
    $appointment_id = $_GET['id'];
    $stmt = $pdo->prepare("UPDATE appointments SET status = 'completed' WHERE id = ? AND doctor_id = ?");
    $stmt->execute([$appointment_id, $doctor_id]);
    header('Location: manage_appointments.php');
    exit;
}

// Get all appointments
$stmt = $pdo->prepare("
    SELECT a.*, p.first_name as patient_first_name, p.last_name as patient_last_name
    FROM appointments a
    JOIN patients p ON a.patient_id = p.id
    WHERE a.doctor_id = ?
    ORDER BY a.appointment_date ASC
");
$stmt->execute([$doctor_id]);
$appointments = $stmt->fetchAll();
?>
<!DOCTYPE html>
<html>
<head>
    <title>Manage Appointments - Hospital Management System</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="header">
        <h1>Manage Appointments</h1>
        <a href="doctor_dashboard.php">Back to Dashboard</a>
    </div>
    <div class="container">
        <h2>All Appointments</h2>
        <table>
            <tr>
                <th>Date & Time</th>
                <th>Patient</th>
                <th>Status</th>
                <th>Notes</th>
                <th>Actions</th>
            </tr>
            <?php foreach ($appointments as $apt): ?>
            <tr>
                <td><?= date('Y-m-d H:i', strtotime($apt['appointment_date'])) ?></td>
                <td><?= htmlspecialchars($apt['patient_first_name'] . ' ' . $apt['patient_last_name']) ?></td>
                <td><?= htmlspecialchars($apt['status']) ?></td>
                <td><?= htmlspecialchars($apt['notes'] ?? 'N/A') ?></td>
                <td>
                    <?php if ($apt['status'] === 'scheduled'): ?>
                    <a href="manage_appointments.php?complete=1&id=<?= $apt['id'] ?>">Mark as Completed</a>
                    <?php endif; ?>
                </td>
            </tr>
            <?php endforeach; ?>
        </table>
    </div>
</body>
</html>

