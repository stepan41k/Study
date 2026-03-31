package unischedule;

import javax.swing.SwingUtilities;

import unischedule.logic.ScheduleManager;
import unischedule.model.Classroom;
import unischedule.model.StudentGroup;
import unischedule.model.Teacher;
import unischedule.ui.MainFrame;

public class Main {
    public static void main(String[] args) {
        ScheduleManager manager = new ScheduleManager();

        try {
            manager.addTeacher(new Teacher("T1", "Смирнов Андрей Викторович"));
            manager.addTeacher(new Teacher("T2", "Иванова Олег Игоревич"));
            manager.addTeacher(new Teacher("T3", "Цымбалюк Лариса Николаевна"));
            manager.addTeacher(new Teacher("T4", "Кулаков Игорь Юрьевич"));
            
            manager.addGroup(new StudentGroup("G3", "3091"));
            manager.addGroup(new StudentGroup("G1", "3092"));
            manager.addGroup(new StudentGroup("G2", "3093"));
            
            manager.addClassroom(new Classroom("R1", "3319"));
            manager.addClassroom(new Classroom("R2", "3312"));
            manager.addClassroom(new Classroom("R3", "3315"));
            manager.addClassroom(new Classroom("R4", "1 Поточная"));
            manager.addClassroom(new Classroom("R5", "2 Поточная"));
        } catch (Exception e) {
            System.err.println("Ошибка при инициализации данных: " + e.getMessage());
        }

        SwingUtilities.invokeLater(() -> {
            MainFrame frame = new MainFrame(manager);
            frame.setVisible(true);
        });
    }
}