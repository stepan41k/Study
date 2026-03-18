package unischedule.logic;

import unischedule.model.*;
import java.util.ArrayList;
import java.util.List;

public class ScheduleManager {
    private final List<Lesson> lessons = new ArrayList<>();
    private final List<Teacher> teachers = new ArrayList<>();
    private final List<StudentGroup> groups = new ArrayList<>();
    private final List<Classroom> classrooms = new ArrayList<>();

    public void addTeacher(Teacher t) { teachers.add(t); }
    public void addGroup(StudentGroup g) { groups.add(g); }
    public void addClassroom(Classroom c) { classrooms.add(c); }

    public List<Teacher> getTeachers() { return teachers; }
    public List<StudentGroup> getGroups() { return groups; }
    public List<Classroom> getClassrooms() { return classrooms; }
    public List<Lesson> getLessons() { return lessons; }

    public void addLesson(Lesson newLesson) throws ConflictException {
        for (Lesson existing : lessons) {
            if (existing.getTimeSlot().equals(newLesson.getTimeSlot())) {
                if (existing.getTeacher().equals(newLesson.getTeacher())) 
                    throw new ConflictException("Преподаватель " + existing.getTeacher() + " уже занят в это время!");
                
                if (existing.getClassroom().equals(newLesson.getClassroom())) 
                    throw new ConflictException("Аудитория " + existing.getClassroom() + " уже занята!");
                
                if (existing.getGroup().equals(newLesson.getGroup())) 
                    throw new ConflictException("Группа " + existing.getGroup() + " уже имеет занятие!");
            }
        }
        lessons.add(newLesson);
    }

    public void removeLesson(int index) {
        if (index >= 0 && index < lessons.size()) lessons.remove(index);
    }
}