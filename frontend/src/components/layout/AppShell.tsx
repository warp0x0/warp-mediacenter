import { Outlet } from 'react-router-dom'
import TabBar from './TabBar'

export default function AppShell() {
  return (
    <div className="h-screen w-screen bg-bg-primary overflow-hidden">
      <TabBar />

      <main className="h-full w-full">
        <Outlet />
      </main>
    </div>
  )
}
