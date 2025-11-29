<?php
session_start();
require_once __DIR__ . '/../config/database.php';

if (!isset($_SESSION['user_id']) || $_SESSION['user_type'] !== 'doctor') {
    header('Location: login.php');
    exit;
}

$pdo = getDatabaseConnection();
$doctor_id = null;

// Get doctor info
$stmt = $pdo->prepare("SELECT d.* FROM doctors d WHERE d.user_id = ?");
$stmt->execute([$_SESSION['user_id']]);
$doctor = $stmt->fetch();
$doctor_id = $doctor['id'];

// Get appointments
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
    <title>Doctor Dashboard - Hospital Management System</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="header">
        <h1>Doctor Dashboard</h1>
        <p>Welcome, Dr. <?= htmlspecialchars($doctor['first_name'] . ' ' . $doctor['last_name']) ?> 
           (<?= htmlspecialchars($doctor['specialization']) ?>)</p>
        <a href="logout.php">Logout</a>
    </div>
    <div class="container">
        <nav>
            <a href="doctor_schedule.php">My Schedule</a>
            <a href="manage_appointments.php">Manage Appointments</a>
        </nav>
        
        <h2>Upcoming Appointments</h2>
        <table>
            <tr>
                <th>Date & Time</th>
                <th>Patient</th>
                <th>Status</th>
                <th>Actions</th>
            </tr>
            <?php foreach ($appointments as $apt): ?>
            <tr>
                <td><?= date('Y-m-d H:i', strtotime($apt['appointment_date'])) ?></td>
                <td><?= htmlspecialchars($apt['patient_first_name'] . ' ' . $apt['patient_last_name']) ?></td>
                <td><?= htmlspecialchars($apt['status']) ?></td>
                <td>
                    <a href="view_appointment.php?id=<?= $apt['id'] ?>">View</a>
                    <?php if ($apt['status'] === 'scheduled'): ?>
                    <a href="complete_appointment.php?id=<?= $apt['id'] ?>">Complete</a>
                    <?php endif; ?>
                </td>
            </tr>
            <?php endforeach; ?>
        </table>
        
        <h2>Calendar Integration</h2>
        <iframe src="https://calendar.google.com/calendar/embed?height=600&wkst=1&bgcolor=%23ffffff&ctz=Europe%2FVilnius" 
                style="border-width:0" width="100%" height="600" frameborder="0" scrolling="no"></iframe>
    </div>
</body>
</html>

