package unischedule.ui;

import java.awt.*;
import java.util.List;
import javax.swing.*;
import unischedule.logic.ScheduleManager;
import unischedule.model.*;

public class ManagementDialog extends JDialog {

    private final ScheduleManager manager;

    public ManagementDialog(JFrame owner, ScheduleManager manager) {
        super(owner, "Управление справочниками", true);
        this.manager = manager;
        setSize(500, 400);
        setLocationRelativeTo(owner);

        JTabbedPane tabs = new JTabbedPane();
        tabs.addTab(
            "Преподаватели",
            createPanel(manager.getTeachers(), "преподавателя")
        );
        tabs.addTab("Группы", createPanel(manager.getGroups(), "группу"));
        tabs.addTab(
            "Аудитории",
            createPanel(manager.getClassrooms(), "аудиторию")
        );

        add(tabs);
    }

    private <T extends ScheduleEntity> JPanel createPanel(
        List<T> list,
        String label
    ) {
        JPanel panel = new JPanel(new BorderLayout());
        DefaultListModel<T> model = new DefaultListModel<>();
        list.forEach(model::addElement);
        JList<T> jList = new JList<>(model);

        JButton btnAdd = new JButton("Добавить");
        JButton btnDel = new JButton("Удалить");

        btnAdd.addActionListener(e -> {
            String name = JOptionPane.showInputDialog(this, "Введите название " + label + ":");
            if (name != null && !name.trim().isEmpty()) {
                name = name.trim();
                String id = String.valueOf(System.currentTimeMillis());
                
                try {
                    if (label.contains("преподавателя")) {
                        Teacher t = new Teacher(id, name);
                        manager.addTeacher(t);
                        model.addElement((T) t);
                    } else if (label.contains("группу")) {
                        StudentGroup g = new StudentGroup(id, name);
                        manager.addGroup(g);
                        model.addElement((T) g);
                    } else if (label.contains("аудиторию")) {
                        Classroom c = new Classroom(id, name);
                        manager.addClassroom(c);
                        model.addElement((T) c);
                    }
                } catch (Exception ex) {
                    JOptionPane.showMessageDialog(this, ex.getMessage(), "Ошибка уникальности", JOptionPane.WARNING_MESSAGE);
                }
            }
        });

        btnDel.addActionListener(e -> {
            T selected = jList.getSelectedValue();
            if (selected != null) {
                try {
                    if (selected instanceof Teacher) manager.removeTeacher(
                        (Teacher) selected
                    );
                    else if (
                        selected instanceof StudentGroup
                    ) manager.removeGroup((StudentGroup) selected);
                    else if (
                        selected instanceof Classroom
                    ) manager.removeClassroom((Classroom) selected);
                    model.removeElement(selected);
                } catch (Exception ex) {
                    JOptionPane.showMessageDialog(
                        this,
                        ex.getMessage(),
                        "Ошибка",
                        JOptionPane.ERROR_MESSAGE
                    );
                }
            }
        });

        JPanel btns = new JPanel();
        btns.add(btnAdd);
        btns.add(btnDel);
        panel.add(new JScrollPane(jList), BorderLayout.CENTER);
        panel.add(btns, BorderLayout.SOUTH);
        return panel;
    }
}
