package unischedule.model;

import java.time.LocalDate;

public abstract class Lesson {
    private LocalDate date;
    private String subject;
    private Teacher teacher;
    private StudentGroup group;
    private Classroom classroom;
    private TimeSlot timeSlot;
    private String comment = "";

    public Lesson(String subject, Teacher teacher, StudentGroup group, Classroom classroom, TimeSlot timeSlot, LocalDate date) {
        this.subject = subject;
        this.teacher = teacher;
        this.group = group;
        this.classroom = classroom;
        this.timeSlot = timeSlot;
        this.date = date;
    }

    public LocalDate getDate() { return date; }
    public String getSubject() { return subject; }
    public Teacher getTeacher() { return teacher; }
    public StudentGroup getGroup() { return group; }
    public Classroom getClassroom() { return classroom; }
    public TimeSlot getTimeSlot() { return timeSlot; }
    public String getComment() { return comment; }
    public abstract String getLessonType();

    public void setDate(LocalDate date) { this.date = date; }
    public void setComment(String comment) { this.comment = comment; }
}