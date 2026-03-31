package unischedule.model;

import java.time.LocalDate;

public class Practice extends Lesson {

    public Practice(
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
        return "Практика";
    }
}
