// controllersession.js
class ControllerSession {
    constructor() {
        this.userKey = 'user';
    }

    // Lấy thông tin người dùng từ localStorage
    getUser() {
        const userData = localStorage.getItem(this.userKey);
        return userData ? JSON.parse(userData) : null;
    }

    // Kiểm tra trạng thái đăng nhập và vai trò controller
    isLoggedInAsController() {
        const user = this.getUser();
        return user && user.isController;
    }

    // Cập nhật thông tin người dùng trên giao diện
    updateUserInterface() {
        const user = this.getUser();
        if (user && user.isController) {
            const userInfoElement = document.getElementById('userInfo');
            if (userInfoElement) {
                userInfoElement.textContent = `Chào ${user.ten || 'Nhân viên kiểm soát'} | `;
                const logoutButton = document.getElementById('logoutButton');
                if (logoutButton) logoutButton.classList.remove('hidden');
            }
        } else {
            // Nếu không phải controller, chuyển hướng về login
            window.location.href = 'login.html';
        }
    }

    // Đăng xuất
    logout() {
        localStorage.removeItem(this.userKey);
        window.location.href = 'login.html';
    }
}

// Khởi tạo instance để sử dụng toàn cục
const controllerSession = new ControllerSession();

// Xuất để dùng ở các file khác
export default controllerSession;