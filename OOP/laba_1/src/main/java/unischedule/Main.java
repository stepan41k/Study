package unischedule;

import unischedule.logic.ScheduleManager;
import unischedule.model.*;
import unischedule.ui.MainFrame;
import javax.swing.SwingUtilities;

public class Main {
    public static void main(String[] args) {
        ScheduleManager manager = new ScheduleManager();

        // Предзаполнение данных (для демонстрации)
        manager.addTeacher(new Teacher("T1", "д.т.н. Смирнов А.В."));
        manager.addTeacher(new Teacher("T2", "к.п.н. Иванова О.И."));
        manager.addGroup(new StudentGroup("G1", "БПИ-23-01"));
        manager.addGroup(new StudentGroup("G2", "БПИ-23-02"));
        manager.addClassroom(new Classroom("R1", "405 ауд."));
        manager.addClassroom(new Classroom("R2", "Лекционный зал №1"));

        SwingUtilities.invokeLater(() -> {
            MainFrame frame = new MainFrame(manager);
            frame.setVisible(true);
        });
    }
}