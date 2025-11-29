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
    <title>My Schedule - Hospital Management System</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="header">
        <h1>My Schedule</h1>
        <a href="doctor_dashboard.php">Back to Dashboard</a>
    </div>
    <div class="container">
        <h2>Appointment Calendar</h2>
        
        <!-- Google Calendar Integration -->
        <iframe src="https://calendar.google.com/calendar/embed?height=600&wkst=1&bgcolor=%23ffffff&ctz=Europe%2FVilnius" 
                style="border-width:0" width="100%" height="600" frameborder="0" scrolling="no"></iframe>
        
        <h2>All Appointments</h2>
        <table>
            <tr>
                <th>Date & Time</th>
                <th>Patient</th>
                <th>Status</th>
                <th>Notes</th>
            </tr>
            <?php foreach ($appointments as $apt): ?>
            <tr>
                <td><?= date('Y-m-d H:i', strtotime($apt['appointment_date'])) ?></td>
                <td><?= htmlspecialchars($apt['patient_first_name'] . ' ' . $apt['patient_last_name']) ?></td>
                <td><?= htmlspecialchars($apt['status']) ?></td>
                <td><?= htmlspecialchars($apt['notes'] ?? 'N/A') ?></td>
            </tr>
            <?php endforeach; ?>
        </table>
    </div>
</body>
</html>

