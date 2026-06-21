# TÀI LIỆU BÁO CÁO & BẢO VỆ DỰ ÁN SOULFLOW

Tài liệu này tóm tắt toàn bộ thông tin chi tiết về ứng dụng **SoulFlow** để phục vụ trực tiếp cho việc ôn tập và trình bày trong buổi bảo vệ đồ án của bạn.

---

## 1. TỔNG QUAN VỀ DỰ ÁN
*   **SoulFlow** là ứng dụng di động hỗ trợ chăm sóc sức khỏe tinh thần, theo dõi cảm xúc hàng ngày, giúp người dùng nhận diện và vượt qua các trạng thái tâm lý tiêu cực.
*   Ứng dụng được xây dựng trên nền tảng **Flutter (Dart)**, sử dụng hệ thống dữ liệu thời gian thực **Firebase (Firestore & Auth)** và mô hình quản lý trạng thái **Provider**.
*   Ứng dụng hoạt động theo cơ chế **Hybrid Storage** (Lưu trữ hỗn hợp): Chạy ngoại tuyến (Offline) bằng cách lưu dữ liệu tạm thời vào thiết bị (`SharedPreferences`), và tự động đồng bộ trực tuyến (Online) lên đám mây khi người dùng đăng nhập tài khoản.

---

## 2. CÁC TÍNH NĂNG CHÍNH VÀ CƠ CHẾ HOẠT ĐỘNG

### 2.1. Đăng ký / Đăng nhập & Khởi động (Auth & Onboarding)
*   **Onboarding**: Giao diện giới thiệu tính năng khi mở ứng dụng lần đầu. Trạng thái xem được lưu lại trong `SharedPreferences` để không lặp lại lần sau.
*   **Xác thực**: Tích hợp **Firebase Auth**, hỗ trợ người dùng đăng nhập bằng Email/Mật khẩu, tài khoản Google, hoặc Đăng nhập ẩn danh để trải nghiệm nhanh.

### 2.2. Nhận diện cảm xúc qua Camera AI
*   **Cách hoạt động**:
    1.  Người dùng mở tính năng quét khuôn mặt, giao diện camera trước hiển thị.
    2.  Khi thanh tiến trình quét đạt **40%**, ứng dụng sẽ chụp một bức ảnh thực tế (`controller.takePicture()`) và tạm dừng tiến trình quét.
    3.  Ứng dụng gửi ảnh chụp sang thư viện **Google ML Kit Face Detection** để phân tích chỉ số nụ cười (`smilingProbability`).
    4.  Quy đổi tỉ lệ cười sang 5 mức cảm xúc: Cười lớn (>65% -> Rất vui), Mỉm cười (>40% -> Vui), Mặt nghiêm nghị (>15% -> Bình thường), Buồn (>5% -> Buồn), Khóc/Rất buồn (<=5% -> Rất buồn).
    5.  Hệ thống cập nhật tỉ lệ cười thật lên màn hình (ví dụ: `Smile: 85%`) rồi tiếp tục chạy tiến trình quét đến 100% để hiển thị kết quả.
    6.  *Chế độ dự phòng (Fallback)*: Trên các thiết bị giả lập hoặc máy tính Windows không hỗ trợ ML Kit native, hệ thống tự động bật chế độ giả lập số ngẫu nhiên để tránh lỗi ứng dụng.

### 2.3. Nhật ký cảm xúc & AI Voice Diary
*   **Nhật ký chữ**: Cho phép người dùng lưu lại cảm xúc và đính kèm các thẻ trạng thái con (Tags).
*   **AI Voice Diary (Nhật ký giọng nói)**: Người dùng có thể nhấn nút nói tiếng Việt, ứng dụng sử dụng thư viện `speech_to_text` để lắng nghe âm thanh và tự động chuyển đổi thành văn bản lưu vào nhật ký.
*   **Tự động phân tích cảm xúc (Sentiment Analysis)**:
    *   Sử dụng bộ dịch vụ `VietnameseSentimentService` chạy 100% offline.
    *   Sử dụng thuật toán so khớp cụm từ tiếng Việt từ dài đến ngắn (Greedy Phrase Matching) dựa trên từ điển cảm xúc được tích hợp sẵn để chấm điểm văn bản nhật ký từ `-5.0` (cực kỳ tiêu cực) đến `5.0` (cực kỳ tích cực).

### 2.4. Dashboard & Biểu đồ thống kê
*   **Biểu đồ LineChart**: Sử dụng thư viện `fl_chart` hiển thị trực quan xu hướng thay đổi cảm xúc của người dùng trong tuần qua.
*   **Nhận diện chuỗi ngày cảm xúc (Streaks)**: Tự động phân tích nếu người dùng có 3 hoặc 7 ngày liên tiếp Vui vẻ (☀️) hoặc Trầm lắng (🌧️).
*   **Chia sẻ phiếu thành tựu**: Nếu đạt chuỗi tích cực liên tiếp, hệ thống cấp một **Phiếu Thành Tựu Vàng** để người dùng chia sẻ trực tiếp vào phòng nhóm chat nhằm lan tỏa năng lượng tích cực.

### 2.5. Phòng chia sẻ nhóm chat (Sharing Room)
*   **Cách hoạt động**: Người dùng tạo phòng để lấy mã gồm 6 ký tự viết hoa, hoặc nhập mã để tham gia vào phòng của bạn bè.
*   **Trò chuyện thời gian thực**: Sử dụng dòng stream dữ liệu Firestore lắng nghe sự thay đổi của tin nhắn để hiển thị ngay lập tức.
*   **Gửi tin nhắn đặc biệt**: Khi người dùng nhấn nút chia sẻ Phiếu thành tựu ở Dashboard, phiếu này sẽ được gửi vào phòng chat dưới dạng tin nhắn định dạng đặc biệt (`type: 'achievement'`), hiển thị thông tin bằng khung viền vàng nổi bật.

### 2.6. Không gian thư giãn (Coping & Zen Space)
*   **Luyện thở chánh niệm (Box Breathing)**: Hướng dẫn người dùng hít thở sâu theo chu kỳ 4 giây (Hít vào - Giữ - Thở ra - Giữ) thông qua hiệu ứng hình cầu co giãn mượt mà.
*   **Kỹ thuật 5-4-3-2-1 Grounding**: Bài tập điều hòa tâm trí bằng cách hướng dẫn người dùng điền thông tin về 5 vật nhìn thấy, 4 vật chạm được... giúp giảm stress tức thì.
*   **Bảng trộn âm thanh (Sound Mixer)**: Sử dụng thư viện `just_audio` để phát và tùy chỉnh âm lượng của từng nguồn âm thanh thiên nhiên khác nhau (tiếng mưa, gió, sóng biển, tiếng chuông chùa) tạo không gian thư giãn cá nhân hóa.

---

## 3. DANH SÁCH THƯ VIỆN & CÔNG NGHỆ SỬ DỤNG
*   **`firebase_core` & `firebase_auth`**: Khởi tạo cấu hình và thực hiện quản lý tài khoản người dùng.
*   **`cloud_firestore`**: Cơ sở dữ liệu NoSQL đám mây thời gian thực, lưu trữ nhật ký cảm xúc, phòng chat và tin nhắn.
*   **`google_mlkit_face_detection`**: Chạy mô hình AI phát hiện khuôn mặt và trích xuất chỉ số nụ cười.
*   **`camera`**: Quản lý phần cứng camera trước của thiết bị.
*   **`speech_to_text`**: Lắng nghe và nhận diện giọng nói tiếng Việt chuyển thành chữ.
*   **`just_audio`**: Phát nhạc thiền và điều khiển mixer âm thanh.
*   **`fl_chart`**: Vẽ biểu đồ đường thể hiện cảm xúc 7 ngày gần nhất.
*   **`shared_preferences`**: Lưu trữ cài đặt Light/Dark mode, Ngôn ngữ, Trạng thái Onboarding và các log offline.
*   **`provider`**: Lớp quản lý trạng thái và cung cấp dữ liệu toàn app (`ThemeProvider`, `LocaleProvider`, `AuthProvider`).
*   **`flutter_local_notifications`**: Thiết lập giờ và hiển thị thông báo đẩy nhắc nhở người dùng ghi chép cảm xúc hàng ngày.

---

## 4. THIẾT KẾ CƠ SỞ DỮ LIỆU (FIRESTORE SCHEMA)

### 4.1. Collection `mood_logs` (Nhật ký cảm xúc)
Mỗi bản ghi đại diện cho một lần ghi nhật ký:
*   `id` (String): ID tự sinh của document.
*   `userId` (String): UID của người dùng (liên kết với Auth).
*   `moodScore` (Int): Điểm cảm xúc (từ 1 đến 5).
*   `note` (String?): Ghi chú cảm xúc viết tay.
*   `tags` (List<String>): Danh sách nhãn cảm xúc đi kèm.
*   `timestamp` (Timestamp): Thời gian tạo bản ghi.
*   `sentimentScore` (Double?): Điểm cảm xúc tự phân tích từ Note (từ `-5.0` đến `5.0`).

### 4.2. Collection `rooms` (Phòng nhóm chat)
Mỗi bản ghi đại diện cho một phòng chat chia sẻ:
*   `code` (String): Mã phòng 6 chữ cái (dùng làm ID Document).
*   `name` (String): Tên phòng nhóm.
*   `createdBy` (String): Người tạo phòng.
*   `members` (List<String>): Danh sách thành viên.
*   **Sub-collection `messages`** (Tin nhắn trong phòng):
    *   `senderId` (String): ID người gửi.
    *   `senderName` (String): Tên hiển thị người gửi.
    *   `text` (String): Nội dung tin nhắn chữ hoặc mô tả thành tựu.
    *   `type` (String): Loại tin nhắn (`text` hoặc `achievement`).
    *   `timestamp` (Timestamp): Thời gian gửi tin nhắn.
    *   `achievementData` (Map): Gồm `title`, `reason`, `date` nếu là tin nhắn chia sẻ thành tựu.

---

## 5. TÓM TẮT VAI TRÒ CÁC FILE CHÍNH
*   `lib/main.dart`: Entrypoint cấu hình app, thiết lập localization tiếng Anh/tiếng Việt và khởi tạo Firebase.
*   `lib/core/services/database_service.dart`: Xử lý trực tiếp các câu lệnh CRUD với Cloud Firestore.
*   `lib/core/services/mood_manager.dart`: Lớp trung gian đồng bộ và quản lý trạng thái dữ liệu Offline - Online.
*   `lib/core/services/sentiment_service.dart`: Phân tích cảm xúc tiếng Việt offline bằng thuật toán Greedy matching.
*   `lib/core/services/notification_service.dart`: Đăng ký kênh thông báo nhắc nhở đẩy hàng ngày.
*   `lib/features/auth/presentation/views/login_screen.dart`: Giao diện đăng nhập.
*   `lib/features/mood/presentation/views/dashboard_view.dart`: Dashboard chính, vẽ biểu đồ đường `LineChart` và tính toán chuỗi ngày tích cực.
*   `lib/features/mood/presentation/views/camera_scanner_overlay.dart`: Giao diện quét camera trước, kết nối ML Kit nhận diện khuôn mặt thực tế.
*   `lib/features/mood/presentation/views/add_mood_screen.dart`: Màn hình ghi chép cảm xúc, thu âm giọng nói chuyển thành chữ.
*   `lib/features/mood/presentation/views/room_view.dart`: Phòng chat nhóm trò chuyện thời gian thực và hiển thị tin nhắn thành tựu.
*   `lib/features/mood/presentation/views/coping_space_view.dart`: Tập hợp các bài tập xoa dịu stress (thở, 5-4-3-2-1, trộn âm thanh).
