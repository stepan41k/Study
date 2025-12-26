using Microsoft.VisualStudio.TestTools.UnitTesting;
using MP9_Password;

namespace MP9_Password.PasswordTest
{
    [TestClass]
    public class PasswordCheckerTests
    {
        // === Тест 1: Корректный пароль ===
        [TestMethod]
        public void Check_CorrectPassword_ReturnsTrue()
        {
            // Arrange
            string password = "ASDqwe123$";
            bool expected = true;

            // Act
            bool actual = PasswordChecker.ValidatePassword(password);

            // Assert
            Assert.AreEqual(expected, actual);
        }

        // === Тест 2: Слишком короткий пароль (меньше 8) ===
        [TestMethod]
        public void Check_ShortPassword_ReturnsFalse()
        {
            // Arrange
            string password = "Aq1$";
            bool expected = false;

            // Act
            bool actual = PasswordChecker.ValidatePassword(password);

            // Assert
            Assert.AreEqual(expected, actual);
        }

        // === Тест 3: Пароль минимальной длины (8 символов) ===
        [TestMethod]
        public void Check_8Symbols_ReturnsTrue()
        {
            // Arrange
            string password = "ASqw12$$";
            bool expected = true;

            // Act
            bool actual = PasswordChecker.ValidatePassword(password);

            // Assert
            Assert.AreEqual(expected, actual);
        }

        // === Тест 4: Слишком длинный пароль (больше 20) ===
        [TestMethod]
        public void Check_LongPassword_ReturnsFalse()
        {
            // Arrange
            string password = "ASDqwe123$ASDqwe123$ASDqwe123$";
            bool expected = false;

            // Act
            bool actual = PasswordChecker.ValidatePassword(password);

            // Assert
            Assert.AreEqual(expected, actual);
        }

        // === Тест 5: Пароль с цифрами (Корректный) ===
        [TestMethod]
        public void Check_PasswordWithDigits_ReturnsTrue()
        {
            // Arrange
            string password = "ASDqwe1$";
            bool expected = true;

            // Act
            bool actual = PasswordChecker.ValidatePassword(password);

            // Assert
            Assert.AreEqual(expected, actual);
        }

        // === Тест 6: Пароль без цифр ===
        [TestMethod]
        public void Check_PasswordWithoutDigits_ReturnsFalse()
        {
            // Arrange
            string password = "ASDqweASD$";
            bool expected = false;

            // Act
            bool actual = PasswordChecker.ValidatePassword(password);

            // Assert
            Assert.AreEqual(expected, actual);
        }

        // === Тест 7: Пароль со спецсимволами ===
        [TestMethod]
        public void Check_PasswordWithSpecialChars_ReturnsTrue()
        {
            // Arrange
            string password = "Aqwe123$";
            bool expected = true;

            // Act
            bool actual = PasswordChecker.ValidatePassword(password);

            // Assert
            Assert.AreEqual(expected, actual);
        }

        // === Тест 8: Пароль без спецсимволов ===
        [TestMethod]
        public void Check_PasswordWithoutSpecialChars_ReturnsFalse()
        {
            // Arrange
            string password = "ASDqwe123";
            bool expected = false;

            // Act
            bool actual = PasswordChecker.ValidatePassword(password);

            // Assert
            Assert.AreEqual(expected, actual);
        }

        // === Тест 9: Пароль без прописных (заглавных) букв ===
        [TestMethod]
        public void Check_PasswordWithUpperCase_ReturnsTrue()
        {
            // Arrange
            string password = "Aqwe123$";
            bool expected = true;

            // Act
            bool actual = PasswordChecker.ValidatePassword(password);

            // Assert
            Assert.AreEqual(expected, actual);
        }

        // === Тест 10: Пароль без прописных (заглавных) букв ===
        [TestMethod]
        public void Check_PasswordWithoutUpperCase_ReturnsFalse()
        {
            // Arrange
            string password = "asdqwe123$";
            bool expected = false;

            // Act
            bool actual = PasswordChecker.ValidatePassword(password);

            // Assert
            Assert.AreEqual(expected, actual);
        }

        // === Тест 11: Пароль без строчных (маленьких) букв ===
        [TestMethod]
        public void Check_PasswordWithLowerCase_ReturnsTrue()
        {
            // Arrange
            string password = "ASDq123$";
            bool expected = true;

            // Act
            bool actual = PasswordChecker.ValidatePassword(password);

            // Assert
            Assert.AreEqual(expected, actual);
        }

        // === Тест 12: Пароль без строчных (маленьких) букв ===
        [TestMethod]
        public void Check_PasswordWithoutLowerCase_ReturnsFalse()
        {
            // Arrange
            string password = "ASDQWE123$";
            bool expected = false;

            // Act
            bool actual = PasswordChecker.ValidatePassword(password);

            // Assert
            Assert.AreEqual(expected, actual);
        }
    }
}