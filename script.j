// --- DESIGN SYSTEM & SETUP ---
const PRIMARY_COLOR = 'var(--color-primary)';
const SUCCESS_COLOR = 'var(--color-success)';
const ERROR_COLOR = 'var(--color-error)';
const API_KEY = "";
const APP_ID = typeof __app_id !== 'undefined' ? __app_id : 'default-placement-app-id';

// Helper function to initialize Lucide icons
const renderIcons = () => {
    if (typeof lucide !== 'undefined') {
        lucide.createIcons();
    }
};

// --- MOCK DATA & STATE MANAGEMENT ---

const MOCK_DATA = {
    roles: ['Student', 'Faculty', 'Recruiter', 'Admin'],
    users: {
        student: { id: 'stu-101', name: 'Alia Khan', role: 'Student', dept: 'CS', year: 4, email: 'alia@campus.edu', skills: ['React', 'Node.js', 'Figma', 'Cloud'], gpa: 9.1 },
        faculty: { id: 'fac-202', name: 'Dr. Rohan Sharma', role: 'Faculty', dept: 'CS', email: 'rohan.s@campus.edu' },
        recruiter: { id: 'rec-303', name: 'Jane Doe (Talent Head)', role: 'Recruiter', company: 'Innovatech Solutions', email: 'jane.d@innovatech.com' },
        admin: { id: 'adm-404', name: 'Mr. Vivek Patel', role: 'Admin', email: 'placement.head@campus.edu' }
    },
    jobs: [
        { id: 1, title: 'Frontend Developer Internship', company: 'Innovatech Solutions', type: 'Internship', stipend: '₹40,000/month', skills: ['React', 'Tailwind', 'JS'], status: 'Open', posted: '2025-09-01', location: 'Remote', applicants: 53, convertToHire: true },
        { id: 2, title: 'Data Scientist Placement', company: 'QuantMetrics', type: 'Placement', stipend: '₹12 LPA', skills: ['Python', 'Pandas', 'ML'], status: 'Open', posted: '2025-08-25', location: 'Bengaluru', applicants: 89, convertToHire: false },
        { id: 3, title: 'UX Designer Internship', company: 'Creative Hub', type: 'Internship', stipend: '₹25,000/month', skills: ['Figma', 'Sketch', 'Prototyping'], status: 'Open', posted: '2025-09-10', location: 'Pune', applicants: 31, convertToHire: true },
    ],
    applications: [
        { id: 101, jobId: 1, studentId: 'stu-101', studentName: 'Alia Khan', facultyStatus: 'Pending', interviewStatus: 'Not Scheduled', applicationDate: '2025-09-15', resume: 'alia_resume.pdf' },
        { id: 102, jobId: 2, studentId: 'stu-101', studentName: 'Alia Khan', facultyStatus: 'Approved', interviewStatus: 'Scheduled', interviewDetails: 'Oct 5, 10:00 AM', applicationDate: '2025-09-12', resume: 'alia_resume.pdf' },
        { id: 103, jobId: 3, studentId: 'stu-101', studentName: 'Alia Khan', facultyStatus: 'Rejected', applicationDate: '2025-09-18', resume: 'alia_resume.pdf', rejectionReason: 'GPA requirement not met.' },
    ],
    reports: [
        { id: 'R001', name: 'CS Department Placement Summary', generated: '2025-09-20', type: 'CSV' },
        { id: 'R002', name: 'Total Unplaced Students', generated: '2025-09-20', type: 'PDF' },
    ],
    auditLog: [
        { timestamp: '2025-09-20 10:30', user: 'Admin', action: 'System settings updated' },
        { timestamp: '2025-09-20 10:20', user: 'Dr. Sharma', action: 'Approved 2 student applications' },
        { timestamp: '2025-09-15 15:45', user: 'Alia Khan', action: 'Applied for Frontend Internship (Job 1)' },
    ]
};

let AppState = {
    isLoggedIn: false,
    user: null, // {id, name, role, ...}
    jobs: MOCK_DATA.jobs,
    applications: MOCK_DATA.applications,
    currentView: 'dashboard',
    skills: MOCK_DATA.users.student.skills || [], // For student profile tags
    jobFilters: { type: '', stipend: '' }
};

const updateState = (newState) => {
    AppState = { ...AppState, ...newState };
    localStorage.setItem(`${APP_ID}-state`, JSON.stringify(AppState));
    renderPage();
};

// Load state from local storage on startup
const loadState = () => {
    try {
        const storedState = localStorage.getItem(`${APP_ID}-state`);
        if (storedState) {
            const loadedState = JSON.parse(storedState);
            AppState = { ...AppState, ...loadedState };
            // Ensure functions are not lost if loading from old state
            if (AppState.skills.length === 0 && AppState.user && AppState.user.role === 'Student') {
                AppState.skills = MOCK_DATA.users.student.skills;
            }
        }
    } catch (e) {
        console.error("Could not load state from localStorage:", e);
    }
};

// --- CORE UI COMPONENTS ---

const Button = (text, onClick, style = 'primary', icon = null, disabled = false) => {
    let baseClasses = `px-4 py-2 rounded-lg font-semibold transition duration-150 ease-in-out flex items-center justify-center space-x-2`;
    let colorClasses = '';

    switch (style) {
        case 'primary':
            colorClasses = 'bg-blue-600 hover:bg-blue-700 text-white shadow-md';
            break;
        case 'secondary':
            colorClasses = 'bg-white border border-gray-300 hover:bg-gray-50 text-gray-700 shadow-sm';
            break;
        case 'ghost':
            colorClasses = 'bg-transparent hover:bg-gray-100 text-gray-700';
            break;
        case 'success':
            colorClasses = 'bg-green-500 hover:bg-green-600 text-white shadow-md';
            break;
        case 'error':
            colorClasses = 'bg-red-500 hover:bg-red-600 text-white shadow-md';
            break;
    }

    if (disabled) {
        colorClasses = 'bg-gray-300 text-gray-500 cursor-not-allowed';
    }

    const iconHtml = icon ? `<i data-lucide="${icon}" class="w-5 h-5"></i>` : '';

    return `
        <button onclick="${disabled ? '' : onClick}" class="${baseClasses} ${colorClasses}" ${disabled ? 'disabled' : ''}>
            ${iconHtml}<span>${text}</span>
        </button>
    `;
};

const TagInput = (id, currentTags, onAdd, onRemove) => {
    const tagsHtml = currentTags.map((tag, index) => `
        <div class="tag">
            ${tag}
            <span class="tag-remove" onclick="${onRemove}('${tag}', ${index})">
                <i data-lucide="x" class="w-4 h-4 text-teal-600 hover:text-teal-800"></i>
            </span>
        </div>
    `).join('');

    return `
        <div class="w-full">
            <div id="${id}-tags" class="tag-input-container">
                ${tagsHtml}
            </div>
            <input type="text" id="${id}-input" placeholder="Add a skill and press Enter"
                class="mt-2 p-2 w-full border border-gray-300 rounded-lg focus:ring-blue-500 focus:border-blue-500"
                onkeydown="if (event.key === 'Enter') { ${onAdd}(document.getElementById('${id}-input').value.trim()); event.preventDefault(); }">
        </div>
    `;
};

const TopBar = () => `
    <header class="bg-white shadow-sm border-b border-gray-200 sticky top-0 z-40">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-3 flex justify-between items-center">
            <div class="flex items-center space-x-4">
                <a href="#" onclick="updateState({currentView: 'dashboard'})" class="text-xl font-bold text-blue-600">
                    Campus Portal
                </a>
                <span class="hidden sm:inline-block px-3 py-1 bg-blue-100 text-blue-800 text-xs font-medium rounded-full">
                    Role: ${AppState.user.role}
                </span>
            </div>
            <div class="flex items-center space-x-4">
                ${Button('', 'alertMessage("Notifications coming soon!")', 'ghost', 'bell')}
                <div class="flex items-center space-x-2 bg-gray-100 p-2 rounded-lg">
                    <i data-lucide="user-circle" class="w-6 h-6 text-gray-500"></i>
                    <span class="font-medium text-gray-800 hidden sm:block">${AppState.user.name}</span>
                </div>
                ${Button('Logout', 'handleLogout()', 'secondary', 'log-out')}
            </div>
        </div>
    </header>
`;

const SideNav = () => {
    const role = AppState.user.role;
    const menuItems = {
        Student: [
            { name: 'Dashboard', icon: 'layout-dashboard', view: 'dashboard' },
            { name: 'Job Search', icon: 'search', view: 'job-search' },
            { name: 'My Applications', icon: 'file-text', view: 'my-applications' },
            { name: 'Profile', icon: 'user', view: 'profile' },
        ],
        Faculty: [
            { name: 'Dashboard', icon: 'layout-dashboard', view: 'dashboard' },
            { name: 'Approval Queue', icon: 'check-square', view: 'approval-queue' },
            { name: 'Feedback', icon: 'message-square', view: 'feedback' },
        ],
        Recruiter: [
            { name: 'Dashboard', icon: 'layout-dashboard', view: 'dashboard' },
            { name: 'Post New Job', icon: 'briefcase', view: 'post-job' },
            { name: 'Manage Postings', icon: 'list', view: 'manage-jobs' },
        ],
        Admin: [
            { name: 'Dashboard', icon: 'layout-dashboard', view: 'dashboard' },
            { name: 'Reporting', icon: 'bar-chart-3', view: 'reporting' },
            { name: 'Audit Log', icon: 'clipboard-list', view: 'audit-log' },
            { name: 'System Settings', icon: 'settings', view: 'settings' },
        ]
    };

    const links = menuItems[role] || [];

    return `
        <nav class="bg-white w-full md:w-64 flex-shrink-0 border-r border-gray-200 p-4 space-y-2">
            ${links.map(item => `
                <a href="#" onclick="updateState({currentView: '${item.view}'})"
                   class="flex items-center p-3 rounded-lg transition duration-150 ease-in-out
                   ${AppState.currentView === item.view ? 'bg-blue-50 text-blue-700 font-semibold border-l-4 border-blue-600' : 'text-gray-600 hover:bg-gray-50'}"
                >
                    <i data-lucide="${item.icon}" class="w-5 h-5 mr-3"></i>
                    ${item.name}
                </a>
            `).join('')}
        </nav>
    `;
};

const JobCard = (job) => {
    const applied = AppState.applications.some(app => app.jobId === job.id && app.studentId === AppState.user.id);
    const statusClass = applied ? 'bg-green-100 text-green-800' : 'bg-blue-100 text-blue-800';
    const statusText = applied ? 'Applied' : 'Apply Now';
    const buttonHtml = applied ?
        Button('Applied', `alertMessage('You have already applied for ${job.title}.')`, 'success', 'check', true) :
        Button('One-Click Apply', `showApplyModal(${job.id})`, 'primary', 'send');

    return `
        <div class="JobCard bg-white p-6 border border-gray-200 rounded-xl shadow-lg hover:shadow-xl transition duration-300 flex flex-col sm:flex-row justify-between space-y-4 sm:space-y-0">
            <div class="flex-grow">
                <div class="flex items-center space-x-3 mb-2">
                    <i data-lucide="briefcase" class="w-6 h-6 text-blue-600"></i>
                    <h3 class="text-xl font-bold text-gray-900">${job.title}</h3>
                </div>
                <p class="text-gray-600 mb-2">${job.company} &bull; ${job.location}</p>
                <div class="flex flex-wrap gap-2 mb-4">
                    <span class="px-3 py-1 text-sm font-medium rounded-full ${statusClass}">${job.type}</span>
                    <span class="px-3 py-1 text-sm font-medium rounded-full bg-indigo-100 text-indigo-800">${job.stipend}</span>
                    ${job.convertToHire ? '<span class="px-3 py-1 text-sm font-medium rounded-full bg-teal-100 text-teal-800">Convert to Hire</span>' : ''}
                </div>
                <div class="mt-3">
                    <p class="text-sm font-medium text-gray-700 mb-1">Required Skills:</p>
                    <div class="flex flex-wrap gap-2">
                        ${job.skills.map(skill => `<span class="px-2 py-0.5 text-xs bg-gray-200 text-gray-700 rounded-md">${skill}</span>`).join('')}
                    </div>
                </div>
            </div>
            <div class="sm:self-center">
                ${buttonHtml}
            </div>
        </div>
    `;
};

const ProfileCard = (user) => `
    <div class="bg-white p-6 rounded-xl shadow-lg border border-gray-200 text-center">
        <i data-lucide="user-circle-2" class="w-20 h-20 mx-auto text-blue-600 mb-3"></i>
        <h2 class="text-2xl font-bold text-gray-900">${user.name}</h2>
        <p class="text-md text-gray-600 mb-4">${user.role} (${user.dept})</p>
        <div class="text-left mt-4 border-t pt-4">
            <p class="text-sm text-gray-500">Email: <span class="font-medium text-gray-700">${user.email}</span></p>
            ${user.gpa ? `<p class="text-sm text-gray-500">GPA: <span class="font-medium text-gray-700">${user.gpa}</span></p>` : ''}
        </div>
        <div class="mt-4">
            ${Button('Edit Profile', 'updateState({currentView: "profile"})', 'secondary', 'edit')}
        </div>
    </div>
`;

const alertMessage = (message, type = 'info') => {
    let bgColor = 'bg-blue-100 border-blue-400 text-blue-700';
    if (type === 'error') bgColor = 'bg-red-100 border-red-400 text-red-700';
    if (type === 'success') bgColor = 'bg-green-100 border-green-400 text-green-700';

    const container = document.getElementById('App');
    const alertDiv = document.createElement('div');
    alertDiv.className = `fixed top-5 right-5 z-50 p-4 rounded-lg shadow-xl border ${bgColor} transition-opacity duration-300`;
    alertDiv.innerHTML = `<p class="font-semibold">${message}</p>`;

    container.appendChild(alertDiv);
    setTimeout(() => {
        alertDiv.style.opacity = '0';
        setTimeout(() => alertDiv.remove(), 300);
    }, 3000);
};

// --- MODAL FUNCTIONS ---

const showModal = (title, bodyHtml, footerHtml = '') => {
    const modalContainer = document.getElementById('ModalContainer');
    const modalContent = document.getElementById('ModalContent');
    modalContent.innerHTML = `
        <div class="p-6 border-b border-gray-200">
            <h3 class="text-2xl font-bold text-gray-900">${title}</h3>
        </div>
        <div class="p-6">
            ${bodyHtml}
        </div>
        <div class="p-4 bg-gray-50 border-t border-gray-200 flex justify-end space-x-3 rounded-b-xl">
            ${Button('Close', 'closeModal()', 'ghost')}
            ${footerHtml}
        </div>
    `;
    modalContainer.classList.remove('hidden');
    modalContainer.classList.add('flex');
    renderIcons();
};

const closeModal = () => {
    const modalContainer = document.getElementById('ModalContainer');
    modalContainer.classList.remove('flex');
    modalContainer.classList.add('hidden');
};

// --- SPECIFIC ROLE WORKFLOWS (MODALS/ACTIONS) ---

// Student Workflow
const showApplyModal = (jobId) => {
    const job = AppState.jobs.find(j => j.id === jobId);
    const body = `
        <div class="space-y-4">
            <p class="text-lg font-medium text-gray-700">Applying for: <span class="font-bold text-blue-600">${job.title} at ${job.company}</span></p>
            <div>
                <label class="block text-sm font-medium text-gray-700">Upload Resume (Mock File Select)</label>
                <input type="file" id="resumeUpload" class="mt-1 block w-full text-sm text-gray-500
                    file:mr-4 file:py-2 file:px-4 file:rounded-full file:border-0
                    file:text-sm file:font-semibold file:bg-blue-50 file:text-blue-700
                    hover:file:bg-blue-100" />
            </div>
            <div>
                <label for="coverLetter" class="block text-sm font-medium text-gray-700">Cover Letter (Optional)</label>
                <textarea id="coverLetter" rows="4" class="mt-1 block w-full p-2 border border-gray-300 rounded-lg focus:ring-blue-500 focus:border-blue-500"></textarea>
            </div>
            <div class="p-3 bg-yellow-50 border border-yellow-200 rounded-lg text-sm text-yellow-800">
                Your application requires Faculty Approval before being sent to the recruiter.
            </div>
        </div>
    `;
    const footer = Button('Submit Application', `handleApplicationSubmission(${jobId})`, 'primary', 'send');
    showModal('Confirm Application', body, footer);
};

const handleApplicationSubmission = (jobId) => {
    const student = AppState.user;
    const newApp = {
        id: AppState.applications.length + 101,
        jobId: jobId,
        studentId: student.id,
        studentName: student.name,
        facultyStatus: 'Pending',
        interviewStatus: 'Not Scheduled',
        applicationDate: new Date().toISOString().slice(0, 10),
        resume: 'placeholder_resume.pdf'
    };

    updateState({ applications: [...AppState.applications, newApp] });
    closeModal();
    alertMessage('Application submitted successfully! Awaiting Faculty Approval.', 'success');
};

// Faculty Workflow
const showApprovalModal = (appId) => {
    const app = AppState.applications.find(a => a.id === appId);
    const job = AppState.jobs.find(j => j.id === app.jobId);

    const body = `
        <div class="space-y-4">
            <p class="text-xl font-bold">${app.studentName}</p>
            <p class="text-md text-gray-600">Applying for: <span class="font-semibold">${job.title} at ${job.company}</span></p>

            <div class="border p-4 rounded-lg bg-gray-50">
                <h4 class="font-semibold mb-2">Review Details (Mock Data)</h4>
                <p class="text-sm">Student GPA: 9.1 (Meets criteria)</p>
                <p class="text-sm">Attendance Check: Satisfactory</p>
                <a href="#" onclick="alertMessage('Mock resume download initiated.')" class="text-blue-600 text-sm hover:underline">Download Resume</a>
            </div>

            <div id="rejectionReasonDiv" class="hidden">
                <label for="rejectionReason" class="block text-sm font-medium text-gray-700">Reason for Rejection</label>
                <textarea id="rejectionReason" rows="3" class="mt-1 block w-full p-2 border border-red-300 rounded-lg focus:ring-red-500 focus:border-red-500" placeholder="State clear, constructive feedback..."></textarea>
            </div>
        </div>
    `;

    const footer = `
        ${Button('Reject', `toggleRejectionForm(${appId})`, 'error', 'x')}
        ${Button('Approve', `handleApprovalAction(${appId}, 'Approved')`, 'success', 'check')}
    `;

    showModal(`Review Application: ${app.id}`, body, footer);
};

const toggleRejectionForm = (appId) => {
    const rejectionDiv = document.getElementById('rejectionReasonDiv');
    const approveButton = document.querySelector(`button[onclick*="handleApprovalAction(${appId}, 'Approved')"]`);
    const rejectButton = document.querySelector(`button[onclick*="toggleRejectionForm(${appId})"]`);

    if (rejectionDiv.classList.contains('hidden')) {
        rejectionDiv.classList.remove('hidden');
        rejectButton.innerHTML = Button('Confirm Reject', `handleApprovalAction(${appId}, 'Rejected')`, 'error', 'x');
        approveButton.classList.add('hidden');
    } else {
        rejectionDiv.classList.add('hidden');
        rejectButton.innerHTML = Button('Reject', `toggleRejectionForm(${appId})`, 'error', 'x');
        approveButton.classList.remove('hidden');
    }
    renderIcons(); // Re-render icons after changing button content
};

const handleApprovalAction = (appId, status) => {
    const reason = status === 'Rejected' ? document.getElementById('rejectionReason').value : '';
    const updatedApps = AppState.applications.map(app =>
        app.id === appId ? { ...app, facultyStatus: status, rejectionReason: reason || undefined } : app
    );

    updateState({ applications: updatedApps });
    closeModal();
    alertMessage(`Application ${appId} successfully marked as ${status}.`, 'success');
};

// Recruiter Workflow
const showSchedulingModal = (appId) => {
    const app = AppState.applications.find(a => a.id === appId);
    const body = `
        <div class="space-y-4">
            <p class="text-xl font-bold">Schedule Interview for ${app.studentName}</p>
            <p class="text-sm text-gray-600">Current Status: <span class="font-semibold text-green-600">Faculty Approved</span></p>

            <div class="p-4 bg-blue-50 border border-blue-200 rounded-lg">
                <label for="interviewDate" class="block text-sm font-medium text-gray-700">Proposed Date & Time</label>
                <input type="datetime-local" id="interviewDate" class="mt-1 block w-full p-2 border border-gray-300 rounded-lg">
            </div>

            <div class="p-4 bg-yellow-50 border border-yellow-200 rounded-lg text-sm text-yellow-800">
                <h4 class="font-semibold mb-1 flex items-center"><i data-lucide="alert-triangle" class="w-4 h-4 mr-2"></i> Conflict Alert</h4>
                <p>Alia Khan has a class conflict from 10:00 AM - 11:30 AM on the proposed date (Oct 5).
                   <br> Suggested alternatives: Oct 5 (12:00 PM) or Oct 6 (any time).
                </p>
            </div>

            <label for="interviewLink" class="block text-sm font-medium text-gray-700">Meeting Link</label>
            <input type="text" id="interviewLink" value="meet.google.com/mock-id" class="mt-1 block w-full p-2 border border-gray-300 rounded-lg">
        </div>
    `;
    const footer = Button('Confirm Schedule', `handleSchedulingAction(${appId})`, 'primary', 'calendar-check');
    showModal('Interview Scheduling', body, footer);
    renderIcons();
};

const handleSchedulingAction = (appId) => {
    const updatedApps = AppState.applications.map(app =>
        app.id === appId ? { ...app, interviewStatus: 'Scheduled', interviewDetails: 'Mock Date/Time' } : app
    );
    updateState({ applications: updatedApps });
    closeModal();
    alertMessage('Interview scheduled successfully! Student has been notified.', 'success');
};
    
// Admin Workflow
const handleReportGenerate = () => {
    const reportName = document.getElementById('reportType').value;
    alertMessage(`Generating new report: ${reportName}... (Check list soon)`, 'info');
    // Mock update
    MOCK_DATA.reports.unshift({ id: 'R003', name: `${reportName} (Newly Generated)`, generated: new Date().toISOString().slice(0, 10), type: 'PDF' });
    renderPage();
};

// --- AUTH AND PAGE RENDER LOGIC ---

const handleLogin = (role) => {
    updateState({
        isLoggedIn: true,
        user: MOCK_DATA.users[role.toLowerCase()],
        currentView: 'dashboard'
    });
};

const handleLogout = () => {
    updateState({
        isLoggedIn: false,
        user: null,
        currentView: 'landing'
    });
    // Clear all user-specific state for true logout simulation
    localStorage.removeItem(`${APP_ID}-state`);
};


// --- VIEW RENDERERS ---

const renderLayout = (contentHtml) => `
    ${AppState.isLoggedIn ? TopBar() : ''}
    <div class="flex flex-1 overflow-hidden">
        ${AppState.isLoggedIn ? SideNav() : ''}
        <main class="flex-1 p-4 md:p-8 overflow-y-auto">
            ${contentHtml}
        </main>
    </div>
`;

const renderLandingPage = () => {
    const header = `
        <div class="text-center py-16 bg-blue-50 border-b border-blue-200 rounded-b-xl">
            <h1 class="text-4xl font-extrabold text-gray-900 mb-3">Campus Career Management Portal</h1>
            <p class="text-lg text-gray-600 max-w-2xl mx-auto">
                Your unified platform for placements, internships, and career growth. Select your role to get started.
            </p>
        </div>
    `;
    const roleSelector = `
        <div class="max-w-4xl mx-auto p-8 -mt-8 bg-white rounded-xl shadow-2xl border border-gray-200">
            <h2 class="text-2xl font-bold text-center mb-6 text-gray-800">Select Demo User Role to Log In</h2>
            <div class="grid grid-cols-2 md:grid-cols-4 gap-6">
                ${MOCK_DATA.roles.map(role => `
                    <div class="role-card p-4 text-center border-2 border-gray-100 rounded-xl hover:border-blue-500 hover:shadow-lg transition duration-200 cursor-pointer" onclick="handleLogin('${role}')">
                        <i data-lucide="${getRoleIcon(role)}" class="w-10 h-10 mx-auto text-blue-600 mb-2"></i>
                        <p class="font-bold text-lg">${role}</p>
                        <p class="text-sm text-gray-500">${MOCK_DATA.users[role.toLowerCase()].name}</p>
                    </div>
                `).join('')}
            </div>

            <div class="mt-8 p-4 bg-gray-50 rounded-lg text-center text-sm text-gray-600 border border-gray-200">
                <i data-lucide="shield-half" class="w-4 h-4 inline mr-2 text-green-600"></i>
                <span class="font-semibold">Privacy & Consent Notice:</span> By logging in, you agree to the mock data usage and client-side storage for this demo MVP.
            </div>
        </div>
    `;

    return `
        <div class="flex-1">
            ${header}
            ${roleSelector}
        </div>
    `;
};

const getRoleIcon = (role) => {
    switch (role) {
        case 'Student': return 'graduation-cap';
        case 'Faculty': return 'school';
        case 'Recruiter': return 'building-2';
        case 'Admin': return 'shield';
        default: return 'user';
    }
};

// --- STUDENT VIEWS ---

const renderStudentDashboard = () => {
    const studentApps = AppState.applications.filter(a => a.studentId === AppState.user.id);
    const pendingApps = studentApps.filter(a => a.facultyStatus === 'Pending').length;
    const scheduledInterviews = studentApps.filter(a => a.interviewStatus === 'Scheduled').length;

    const latestApplications = studentApps
        .sort((a, b) => new Date(b.applicationDate) - new Date(a.applicationDate))
        .slice(0, 5);

    const timelineHtml = latestApplications.map((app, index) => {
        const job = AppState.jobs.find(j => j.id === app.jobId);
        let statusText = `${app.facultyStatus} by Faculty`;
        let icon = 'clock';
        let color = 'text-yellow-600';

        if (app.facultyStatus === 'Approved') {
            statusText = app.interviewStatus === 'Scheduled' ? `Interview Scheduled (${app.interviewDetails})` : 'Approved by Faculty';
            icon = 'check-circle';
            color = 'text-green-600';
        } else if (app.facultyStatus === 'Rejected') {
            statusText = 'Rejected by Faculty';
            icon = 'x-circle';
            color = 'text-red-600';
        }

        return `
            <div class="timeline-item relative pl-8 pb-8 ${index === 0 ? 'active' : ''}">
                <div class="timeline-item-line ${index === latestApplications.length - 1 ? 'hidden' : ''}"></div>
                <div class="absolute left-0 top-0 mt-1">
                    <i data-lucide="${icon}" class="w-4 h-4 ${color}"></i>
                </div>
                <p class="font-semibold text-gray-800">${job.title} at ${job.company}</p>
                <p class="text-sm text-gray-600">${statusText}</p>
                <span class="text-xs text-gray-400">${app.applicationDate}</span>
            </div>
        `;
    }).join('');

    return `
        <h1 class="text-3xl font-bold mb-6 text-gray-900">Student Dashboard</h1>
        <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
            ${renderKPICard('Applications Applied', studentApps.length, 'file-text', 'text-blue-600')}
            ${renderKPICard('Pending Faculty Approval', pendingApps, 'loader-2', 'text-yellow-600')}
            ${renderKPICard('Upcoming Interviews', scheduledInterviews, 'calendar-check', 'text-green-600')}
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
            <div class="lg:col-span-2 space-y-6">
                <div class="bg-white p-6 rounded-xl shadow-lg border border-gray-200">
                    <h2 class="text-xl font-bold mb-4 text-gray-800">Quick Links</h2>
                    <div class="grid grid-cols-2 gap-4">
                        ${Button('Search Jobs', `updateState({currentView: 'job-search'})`, 'primary', 'search')}
                        ${Button('Manage Profile', `updateState({currentView: 'profile'})`, 'secondary', 'user')}
                    </div>
                </div>

                <div class="bg-white p-6 rounded-xl shadow-lg border border-gray-200">
                    <h2 class="text-xl font-bold mb-4 text-gray-800">Job Recommendations</h2>
                    ${JobCard(AppState.jobs[0])}
                    <div class="mt-4 text-center">
                        <a href="#" onclick="updateState({currentView: 'job-search'})" class="text-blue-600 font-medium hover:underline">View All Jobs</a>
                    </div>
                </div>
            </div>
            <div class="lg:col-span-1 bg-white p-6 rounded-xl shadow-lg border border-gray-200">
                <h2 class="text-xl font-bold mb-4 text-gray-800">Application Timeline</h2>
                <div class="relative pt-4">
                    ${timelineHtml}
                </div>
            </div>
        </div>
    `;
};

const renderStudentProfile = () => {
    const user = AppState.user;
    const handleAddSkill = (skill) => {
        if (skill && !AppState.skills.includes(skill)) {
            updateState({ skills: [...AppState.skills, skill] });
            document.getElementById('skills-input').value = '';
        }
    };
    const handleRemoveSkill = (skill) => {
        updateState({ skills: AppState.skills.filter(s => s !== skill) });
    };

    // Expose these handlers globally for use in the component string
    window.handleAddSkill = handleAddSkill;
    window.handleRemoveSkill = handleRemoveSkill;

    return `
        <h1 class="text-3xl font-bold mb-6 text-gray-900">My Profile</h1>
        <div class="bg-white p-8 rounded-xl shadow-lg border border-gray-200 max-w-4xl mx-auto space-y-8">
            <div>
                <h2 class="text-xl font-bold text-gray-800 mb-4 border-b pb-2">Personal & Academic Details</h2>
                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                    ${renderFormInput('text', 'Full Name', 'name', user.name)}
                    ${renderFormInput('text', 'Email (Read-Only)', 'email', user.email, true)}
                    ${renderFormInput('text', 'Department', 'dept', user.dept)}
                    ${renderFormInput('number', 'Current GPA (9.0 Scale)', 'gpa', user.gpa)}
                </div>
            </div>

            <div>
                <h2 class="text-xl font-bold text-gray-800 mb-4 border-b pb-2">Skills & Expertise</h2>
                <label class="block text-sm font-medium text-gray-700 mb-1">Technical/Soft Skills</label>
                ${TagInput('skills', AppState.skills, 'handleAddSkill', 'handleRemoveSkill')}
            </div>

            <div>
                <h2 class="text-xl font-bold text-gray-800 mb-4 border-b pb-2">Documents & Consent</h2>
                <div class="space-y-4">
                    ${renderFormInput('file', 'Upload Latest Resume', 'resume')}
                    <div class="flex items-start space-x-3 p-3 bg-gray-50 rounded-lg">
                        <input id="consentToggle" type="checkbox" class="mt-1 h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500" checked>
                        <label for="consentToggle" class="text-sm font-medium text-gray-700">
                            I consent to share my profile details with faculty and authorized recruiters.
                        </label>
                    </div>
                </div>
            </div>

            <div class="pt-6 border-t flex justify-end">
                ${Button('Save Changes', `alertMessage('Profile saved!', 'success')`, 'primary', 'save')}
            </div>
        </div>
    `;
};

const renderJobSearch = () => {
    const filterJobs = () => {
        let filtered = MOCK_DATA.jobs;
        if (AppState.jobFilters.type) {
            filtered = filtered.filter(j => j.type === AppState.jobFilters.type);
        }
        if (AppState.jobFilters.stipend === 'High') {
            filtered = filtered.filter(j => parseInt(j.stipend.replace(/[^0-9]/g, '')) >= 10); // Simple mock check for LPA/monthly
        }
        return filtered;
    };

    const filteredJobs = filterJobs();

    const jobCards = filteredJobs.map(job => JobCard(job)).join('');

    const handleFilterChange = (key, value) => {
        updateState({ jobFilters: { ...AppState.jobFilters, [key]: value } });
    };
    window.handleFilterChange = handleFilterChange;

    return `
        <h1 class="text-3xl font-bold mb-6 text-gray-900">Job & Internship Discovery</h1>

        <div class="grid grid-cols-1 lg:grid-cols-4 gap-6">
            <div class="lg:col-span-1 bg-white p-6 rounded-xl shadow-lg border border-gray-200 h-fit sticky top-20">
                <h2 class="text-xl font-bold mb-4 border-b pb-2">Filters</h2>
                <div class="space-y-6">
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-2">Opportunity Type</label>
                        ${renderFilterButton('type', 'All', '')}
                        ${renderFilterButton('type', 'Internship', 'Internship')}
                        ${renderFilterButton('type', 'Placement', 'Placement')}
                    </div>

                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-2">Stipend/Salary</label>
                        ${renderFilterButton('stipend', 'All', '')}
                        ${renderFilterButton('stipend', 'High (>₹10 LPA)', 'High')}
                        ${renderFilterButton('stipend', 'Medium', 'Medium')}
                    </div>

                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-2">Skill Match</label>
                        <div class="p-3 bg-gray-100 rounded-lg text-sm text-gray-600">
                            Your skills match 3 jobs.
                        </div>
                    </div>
                </div>
            </div>

            <div class="lg:col-span-3 space-y-6">
                ${filteredJobs.length > 0 ? jobCards : '<p class="text-center text-lg text-gray-500 p-10 bg-white rounded-xl shadow-lg">No jobs match your current filters.</p>'}
            </div>
        </div>
    `;
};

const renderFilterButton = (key, text, value) => {
    const isActive = AppState.jobFilters[key] === value;
    return `
        <button onclick="window.handleFilterChange('${key}', '${value}')"
            class="mr-2 mb-2 px-3 py-1 text-sm rounded-full transition duration-150
            ${isActive ? 'bg-blue-600 text-white font-semibold shadow-md' : 'bg-gray-100 text-gray-700 hover:bg-gray-200'}"
        >
            ${text}
        </button>
    `;
};

const renderMyApplications = () => {
    const studentApps = AppState.applications.filter(a => a.studentId === AppState.user.id);

    const appRows = studentApps.map(app => {
        const job = AppState.jobs.find(j => j.id === app.jobId);
        let facultyBadge = renderBadge(app.facultyStatus, { Pending: 'yellow', Approved: 'green', Rejected: 'red' });
        let interviewBadge = renderBadge(app.interviewStatus, { 'Not Scheduled': 'gray', Scheduled: 'blue' });

        return `
            <tr class="hover:bg-gray-50">
                <td class="px-6 py-4 text-sm font-medium text-gray-900">${job.title}</td>
                <td class="px-6 py-4 text-sm text-gray-500">${job.company}</td>
                <td class="px-6 py-4 text-sm">${facultyBadge}</td>
                <td class="px-6 py-4 text-sm">${interviewBadge}</td>
                <td class="px-6 py-4 text-sm text-gray-500">${app.applicationDate}</td>
                <td class="px-6 py-4 text-sm space-x-2">
                    ${app.interviewStatus === 'Scheduled' ? Button('View Details', `alertMessage('Interview details: ${app.interviewDetails}', 'info')`, 'ghost', 'eye') : ''}
                    ${app.facultyStatus === 'Rejected' ? Button('View Feedback', `alertMessage('${app.rejectionReason || 'No specific feedback provided.'}', 'info')`, 'secondary', 'message-square') : ''}
                </td>
            </tr>
        `;
    }).join('');

    return `
        <h1 class="text-3xl font-bold mb-6 text-gray-900">My Applications</h1>
        <div class="bg-white rounded-xl shadow-lg border border-gray-200 overflow-hidden">
            <div class="overflow-x-auto">
                <table class="min-w-full divide-y divide-gray-200">
                    <thead class="bg-gray-50">
                        <tr>
                            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Job Title</th>
                            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Company</th>
                            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Faculty Approval</th>
                            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Interview Status</th>
                            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Applied On</th>
                            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                        </tr>
                    </thead>
                    <tbody class="bg-white divide-y divide-gray-200">
                        ${studentApps.length > 0 ? appRows : `<tr><td colspan="6" class="p-8 text-center text-gray-500">You have no applications yet.</td></tr>`}
                    </tbody>
                </table>
            </div>
        </div>
    `;
};

// --- FACULTY VIEWS ---

const renderFacultyDashboard = () => {
    const pendingQueue = AppState.applications.filter(a => a.facultyStatus === 'Pending');
    const totalApproved = AppState.applications.filter(a => a.facultyStatus === 'Approved').length;

    const pendingCards = pendingQueue.map(app => {
        const job = AppState.jobs.find(j => j.id === app.jobId);
        const student = MOCK_DATA.users.student; // Mock student data access

        return `
            <div class="bg-white p-5 border border-gray-200 rounded-xl shadow-md flex justify-between items-center space-x-4">
                <div class="flex-1">
                    <p class="font-bold text-gray-900">${app.studentName} (${student.dept})</p>
                    <p class="text-sm text-gray-600">Applied for: <span class="font-medium">${job.title} at ${job.company}</span></p>
                </div>
                <div class="flex space-x-2">
                    ${Button('Review', `showApprovalModal(${app.id})`, 'secondary', 'search')}
                    ${Button('Quick Approve', `handleApprovalAction(${app.id}, 'Approved')`, 'success', 'check')}
                </div>
            </div>
        `;
    }).join('');

    return `
        <h1 class="text-3xl font-bold mb-6 text-gray-900">Faculty Dashboard</h1>
        <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
            ${renderKPICard('Pending Approvals', pendingQueue.length, 'check-square', 'text-red-600')}
            ${renderKPICard('Total Approved (This Month)', totalApproved, 'thumbs-up', 'text-green-600')}
            ${renderKPICard('Pending Certificates', 2, 'award', 'text-yellow-600')}
        </div>

        <div class="bg-white p-6 rounded-xl shadow-lg border border-gray-200">
            <h2 class="text-xl font-bold mb-4 text-gray-800 flex justify-between items-center">
                Application Approval Queue
                ${pendingQueue.length > 1 ? Button('Batch Approve All', `alertMessage('Mock Batch Approve: All ${pendingQueue.length} applications approved!', 'success')`, 'primary', 'check-check') : ''}
            </h2>
            <div class="space-y-3">
                ${pendingQueue.length > 0 ? pendingCards : '<p class="p-4 text-center text-gray-500 bg-gray-50 rounded-lg">The approval queue is empty. Great job!</p>'}
            </div>
        </div>
    `;
};

const renderApprovalQueue = () => {
    // Re-use Faculty Dashboard content for a richer "queue" view
    return renderFacultyDashboard();
};

// --- RECRUITER VIEWS ---

const renderRecruiterDashboard = () => {
    const totalApplicants = AppState.jobs.reduce((sum, job) => sum + job.applicants, 0);
    const activePostings = AppState.jobs.filter(j => j.status === 'Open').length;

    const jobRows = AppState.jobs.map(job => {
        return `
            <tr class="hover:bg-gray-50">
                <td class="px-6 py-4 text-sm font-medium text-gray-900">${job.title}</td>
                <td class="px-6 py-4 text-sm text-gray-500">${job.applicants}</td>
                <td class="px-6 py-4 text-sm">${renderBadge(job.status, { Open: 'green' })}</td>
                <td class="px-6 py-4 text-sm space-x-2">
                    ${Button('View Applicants (Mock)', `alertMessage('Navigating to applicants for ${job.title}')`, 'secondary', 'users')}
                    ${Button('Close Posting', `alertMessage('Posting ${job.title} closed (Mock)')`, 'error', 'lock')}
                </td>
            </tr>
        `;
    }).join('');


    return `
        <h1 class="text-3xl font-bold mb-6 text-gray-900">Recruiter Dashboard</h1>
        <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
            ${renderKPICard('Active Postings', activePostings, 'briefcase', 'text-blue-600')}
            ${renderKPICard('Total Applicants', totalApplicants, 'users', 'text-purple-600')}
            ${renderKPICard('Interviews Scheduled (Mock)', 4, 'calendar', 'text-green-600')}
        </div>

        <div class="space-y-6">
            ${Button('Post a New Job', `updateState({currentView: 'post-job'})`, 'primary', 'plus')}

            <div class="bg-white rounded-xl shadow-lg border border-gray-200 overflow-hidden">
                <div class="p-5 border-b flex justify-between items-center">
                    <h2 class="text-xl font-bold text-gray-800">Your Active Job Postings</h2>
                </div>
                <div class="overflow-x-auto">
                    <table class="min-w-full divide-y divide-gray-200">
                        <thead class="bg-gray-50">
                            <tr>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Job Title</th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Applicants</th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                            </tr>
                        </thead>
                        <tbody class="bg-white divide-y divide-gray-200">
                            ${jobRows}
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    `;
};

const renderPostJob = () => {
    const tempJobSkills = ['JavaScript', 'HTML', 'CSS'];

    const handleAddTempSkill = (skill) => {
        if (skill && !tempJobSkills.includes(skill)) {
            tempJobSkills.push(skill);
            renderPage(); // Rerender to show new tag
        }
    };
    const handleRemoveTempSkill = (skill, index) => {
        tempJobSkills.splice(index, 1);
        renderPage(); // Rerender to update tag list
    };
    window.handleAddTempSkill = handleAddTempSkill;
    window.handleRemoveTempSkill = handleRemoveTempSkill;

    const handleJobPost = () => {
        const title = document.getElementById('jobTitle').value;
        const newJob = {
            id: AppState.jobs.length + 1,
            title: title || 'New Posted Job',
            company: AppState.user.company,
            type: document.getElementById('jobType').value,
            stipend: document.getElementById('stipend').value,
            skills: tempJobSkills,
            status: 'Open',
            posted: new Date().toISOString().slice(0, 10),
            location: document.getElementById('location').value,
            applicants: 0,
            convertToHire: document.getElementById('convertToggle').checked
        };
        updateState({ jobs: [...AppState.jobs, newJob] });
        alertMessage(`Job "${newJob.title}" posted successfully!`, 'success');
        updateState({currentView: 'manage-jobs'});
    };

    return `
        <h1 class="text-3xl font-bold mb-6 text-gray-900">Post a New Job/Internship</h1>
        <div class="bg-white p-8 rounded-xl shadow-lg border border-gray-200 max-w-4xl mx-auto space-y-6">
            <div>
                <h2 class="text-xl font-bold text-gray-800 mb-4 border-b pb-2">Basic Details</h2>
                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                    ${renderFormInput('text', 'Job Title', 'jobTitle', '', false, 'Frontend Developer Internship')}
                    ${renderFormSelect('Job Type', 'jobType', ['Internship', 'Placement'])}
                    ${renderFormInput('text', 'Stipend/Salary (e.g., ₹40,000/mo or ₹12 LPA)', 'stipend')}
                    ${renderFormInput('text', 'Location', 'location', 'Remote/Hybrid')}
                </div>
            </div>

            <div>
                <h2 class="text-xl font-bold text-gray-800 mb-4 border-b pb-2">Description & Requirements</h2>
                ${renderFormTextarea('Job Description', 'description', 'Provide a detailed job description...')}
                <label class="block text-sm font-medium text-gray-700 mt-4 mb-1">Required Skills (Tags)</label>
                ${TagInput('job-skills', tempJobSkills, 'handleAddTempSkill', 'handleRemoveTempSkill')}
            </div>

            <div>
                <h2 class="text-xl font-bold text-gray-800 mb-4 border-b pb-2">Placement Settings</h2>
                <div class="flex items-start space-x-3 p-3 bg-gray-50 rounded-lg">
                    <input id="convertToggle" type="checkbox" class="mt-1 h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500" checked>
                    <label for="convertToggle" class="text-sm font-medium text-gray-700">
                        This opportunity has a **Convert to Hire** option for high performers.
                    </label>
                </div>
            </div>

            <div class="pt-6 border-t flex justify-end">
                ${Button('Post Job', `handleJobPost()`, 'primary', 'upload')}
            </div>
        </div>
    `;
};

// --- ADMIN VIEWS ---

const renderAdminDashboard = () => {
    const totalStudents = 350;
    const placedStudents = 120;
    const unplacedStudents = totalStudents - placedStudents;

    return `
        <h1 class="text-3xl font-bold mb-6 text-gray-900">Admin Dashboard (Placement Head)</h1>

        <div class="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
            ${renderKPICard('Total Students', totalStudents, 'users-2', 'text-gray-600')}
            ${renderKPICard('Students Placed', placedStudents, 'trending-up', 'text-green-600')}
            ${renderKPICard('Unplaced Students', unplacedStudents, 'trending-down', 'text-red-600')}
            ${renderKPICard('Active Recruiters', 25, 'building', 'text-blue-600')}
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
            <div class="lg:col-span-2 bg-white p-6 rounded-xl shadow-lg border border-gray-200">
                <h2 class="text-xl font-bold mb-4">Placement Rate by Department (Mock Chart)</h2>
                <div class="h-64 bg-gray-100 flex items-center justify-center rounded-lg text-gray-500">
                    [Placeholder: Bar Chart showing CS: 75%, EC: 60%, MECH: 45%]
                </div>
            </div>
            <div class="lg:col-span-1 bg-white p-6 rounded-xl shadow-lg border border-gray-200">
                <h2 class="text-xl font-bold mb-4">Quick Actions</h2>
                <div class="space-y-3">
                     ${Button('Generate Reports', `updateState({currentView: 'reporting'})`, 'secondary', 'bar-chart-3')}
                     ${Button('View Audit Log', `updateState({currentView: 'audit-log'})`, 'secondary', 'clipboard-list')}
                     ${Button('Manage Recruiters (Mock)', `alertMessage('Navigating to recruiter management.')`, 'secondary', 'building-2')}
                </div>
            </div>
        </div>
    `;
};

const renderReporting = () => {
    const reportRows = MOCK_DATA.reports.map(report => `
        <tr class="hover:bg-gray-50">
            <td class="px-6 py-4 text-sm font-medium text-gray-900">${report.name}</td>
            <td class="px-6 py-4 text-sm text-gray-500">${report.generated}</td>
            <td class="px-6 py-4 text-sm">${renderBadge(report.type, { PDF: 'red', CSV: 'blue' })}</td>
            <td class="px-6 py-4 text-sm space-x-2">
                ${Button('Download', `alertMessage('Downloading ${report.type} report for ${report.name}')`, 'ghost', 'download')}
            </td>
        </tr>
    `).join('');
    
    // NOTE: handleReportGenerate definition moved to global scope.

    return `
        <h1 class="text-3xl font-bold mb-6 text-gray-900">Reporting & Analytics</h1>
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
            <div class="lg:col-span-1 bg-white p-6 rounded-xl shadow-lg border border-gray-200 h-fit">
                <h2 class="text-xl font-bold mb-4 border-b pb-2">Generate New Report</h2>
                ${renderFormSelect('Report Type', 'reportType', ['Student Placement Summary', 'GPA Distribution', 'Recruiter Activity', 'Pending Approvals'])}
                <div class="mt-6">
                    ${Button('Generate Report', 'handleReportGenerate()', 'primary', 'trending-up')}
                </div>
            </div>

            <div class="lg:col-span-2 bg-white rounded-xl shadow-lg border border-gray-200 overflow-hidden">
                 <div class="p-5 border-b">
                    <h2 class="text-xl font-bold text-gray-800">Available Reports</h2>
                </div>
                <div class="overflow-x-auto">
                    <table class="min-w-full divide-y divide-gray-200">
                        <thead class="bg-gray-50">
                            <tr>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Report Name</th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Generated On</th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Format</th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                            </tr>
                        </thead>
                        <tbody class="bg-white divide-y divide-gray-200">
                            ${reportRows}
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    `;
};

const renderAuditLog = () => {
    const logRows = MOCK_DATA.auditLog.map(log => `
        <tr class="hover:bg-gray-50">
            <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">${log.timestamp}</td>
            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-600">${log.user}</td>
            <td class="px-6 py-4 text-sm text-gray-500">${log.action}</td>
        </tr>
    `).join('');

    return `
        <h1 class="text-3xl font-bold mb-6 text-gray-900">System Audit Log</h1>
        <div class="bg-white rounded-xl shadow-lg border border-gray-200 overflow-hidden">
             <div class="p-5 border-b">
                <h2 class="text-xl font-bold text-gray-800">Client-Side Activity Log (Read-Only Mock)</h2>
            </div>
            <div class="overflow-x-auto">
                <table class="min-w-full divide-y divide-gray-200">
                    <thead class="bg-gray-50">
                        <tr>
                            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Timestamp</th>
                            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">User</th>
                            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Action</th>
                        </tr>
                    </thead>
                    <tbody class="bg-white divide-y divide-gray-200">
                        ${logRows}
                    </tbody>
                </table>
            </div>
        </div>
    `;
};


// --- GENERIC RENDER HELPERS ---

const renderKPICard = (title, value, icon, iconClass) => `
    <div class="bg-white p-5 rounded-xl shadow-lg border border-gray-200 flex items-center space-x-4">
        <div class="p-3 rounded-full ${iconClass} bg-opacity-10">
            <i data-lucide="${icon}" class="w-6 h-6 ${iconClass}"></i>
        </div>
        <div>
            <p class="text-sm font-medium text-gray-500">${title}</p>
            <p class="text-2xl font-bold text-gray-900">${value}</p>
        </div>
    </div>
`;

const renderBadge = (text, colorMap) => {
    const color = colorMap[text] || 'gray';
    const bgColor = `bg-${color}-100`;
    const textColor = `text-${color}-800`;
    return `<span class="px-2.5 py-0.5 text-xs font-medium rounded-full ${bgColor} ${textColor}">${text}</span>`;
};

const renderFormInput = (type, label, id, value = '', readOnly = false, placeholder = '') => `
    <div>
        <label for="${id}" class="block text-sm font-medium text-gray-700">${label}</label>
        <input type="${type}" id="${id}" value="${value}"
            class="mt-1 block w-full p-3 border border-gray-300 rounded-lg shadow-sm
            focus:ring-blue-500 focus:border-blue-500 ${readOnly ? 'bg-gray-100' : ''}"
            ${readOnly ? 'readonly' : ''} placeholder="${placeholder}">
    </div>
`;

const renderFormTextarea = (label, id, placeholder = '') => `
    <div>
        <label for="${id}" class="block text-sm font-medium text-gray-700">${label}</label>
        <textarea id="${id}" rows="4" class="mt-1 block w-full p-3 border border-gray-300 rounded-lg shadow-sm
            focus:ring-blue-500 focus:border-blue-500" placeholder="${placeholder}"></textarea>
    </div>
`;

const renderFormSelect = (label, id, options) => `
    <div>
        <label for="${id}" class="block text-sm font-medium text-gray-700">${label}</label>
        <select id="${id}" class="mt-1 block w-full p-3 border border-gray-300 rounded-lg shadow-sm
            focus:ring-blue-500 focus:border-blue-500 bg-white">
            ${options.map(opt => `<option value="${opt}">${opt}</option>`).join('')}
        </select>
    </div>
`;

// --- MAIN APPLICATION RENDERER ---

const renderPage = () => {
    const app = document.getElementById('App');
    let content = '';

    if (!AppState.isLoggedIn || !AppState.user) {
        content = renderLandingPage();
    } else {
        let mainContentHtml = '';
        const role = AppState.user.role;

        const roleViewMap = {
            'Student': {
                'dashboard': renderStudentDashboard,
                'job-search': renderJobSearch,
                'profile': renderStudentProfile,
                'my-applications': renderMyApplications,
            },
            'Faculty': {
                'dashboard': renderFacultyDashboard,
                'approval-queue': renderApprovalQueue,
                'feedback': () => `<h1 class="text-3xl font-bold">Feedback/Certificate Flow (Mock)</h1><div class="p-10 bg-white rounded-xl shadow-lg mt-6">Mock form for providing feedback and triggering client-side certificate generation.</div>`,
            },
            'Recruiter': {
                'dashboard': renderRecruiterDashboard,
                'post-job': renderPostJob,
                'manage-jobs': renderRecruiterDashboard, // Using dashboard as main management view
            },
            'Admin': {
                'dashboard': renderAdminDashboard,
                'reporting': renderReporting,
                'audit-log': renderAuditLog,
                'settings': () => `<h1 class="text-3xl font-bold">System Settings (Mock)</h1><div class="p-10 bg-white rounded-xl shadow-lg mt-6">Mock UI for managing global settings and user roles.</div>`,
            }
        };

        const renderer = roleViewMap[role][AppState.currentView] || roleViewMap[role]['dashboard'];
        mainContentHtml = renderer();

        content = renderLayout(mainContentHtml);
    }

    app.innerHTML = content;
    renderIcons(); // Re-render Lucide icons after DOM update
};

// --- INITIALIZATION ---
window.onload = () => {
    loadState();
    renderPage();
    // Expose utility functions globally for inline HTML/JS calls
    window.handleLogin = handleLogin;
    window.handleLogout = handleLogout;
    window.updateState = updateState;
    window.showApplyModal = showApplyModal;
    window.handleApplicationSubmission = handleApplicationSubmission;
    window.showApprovalModal = showApprovalModal;
    window.handleApprovalAction = handleApprovalAction;
    window.toggleRejectionForm = toggleRejectionForm;
    window.showSchedulingModal = showSchedulingModal;
    window.handleSchedulingAction = handleSchedulingAction;
    window.handleReportGenerate = handleReportGenerate;
    window.alertMessage = alertMessage;
    window.closeModal = closeModal;
    window.renderPage = renderPage; // for re-rendering tags
};
