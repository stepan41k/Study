package unischedule.model;

import java.time.LocalDate;

public class Labaratory extends Lesson {

    public Labaratory(
        String subject,
        Teacher t,
        StudentGroup g,
        Classroom c,
        TimeSlot ts,
        LocalDate d
    ) {
        super(subject, t, g, c, ts, d);
    }

    @Override
    public String getLessonType() {
        return "Лабараторная";
    }
}
